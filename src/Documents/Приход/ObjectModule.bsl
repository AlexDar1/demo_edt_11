
Процедура ОбработкаПроведения() 
	
	Движения.ОплатыЗаУслуги.Записывать = Истина;
	Движение = Движения.ОплатыЗаУслуги.Добавить();
	Движение.Период = Дата;
	Движение.ВидУслуги = Перечисления.ВидыУслуг.Хранение;
	Движение.Сумма = ПолучитьОбщуюСтоимостьХранения (ДатаПрибытия, ДатаУбытия, ТипГрузовогоМеста); 
	
    Движения.ОплатыЗаУслуги.Записывать = Истина;
	Движение = Движения.ОплатыЗаУслуги.Добавить();
	Движение.Период = Дата;
	Движение.ВидУслуги = Перечисления.ВидыУслуг.Обработка;
	Движение.Сумма = ПолучитьОбщуюСтоимостьОбработки(ДатаПрибытия, ДатаУбытия, ТипГрузовогоМеста); 
	
	
КонецПроцедуры 

Функция  ПолучитьОбщуюСтоимостьХранения (ДатаОт, ДатаДо, ТипГрузовогоМеста)
	
	ОбщаяСтоимостьХранения = 0;
	ОдниСуткиВСекундах = 86400;
	ОбщееВремяНаХраненииВСутках = (ДатаУбытия - ДатаПрибытия)/ОдниСуткиВСекундах;
	
	Если ОбщееВремяНаХраненииВСутках < 1 Тогда  
		//Если меньше суток, то оплату за хранение не выставляем
		Возврат ОбщаяСтоимостьХранения;
	КонецЕсли;	 
	
	ОбщееВремяНаХраненииВДнях = (НачалоДня(ДатаДо) - НачалоДня(ДатаОт))/ОдниСуткиВСекундах;
	
	Если ОбщееВремяНаХраненииВСутках < ОбщееВремяНаХраненииВДнях Тогда 
		//Если одни сутки, проведенные на хранении были не полные, тогда за последние сутки счет не выставляем
		ДатаУбытия = ДатаУбытия - ОдниСуткиВСекундах;
	КонецЕсли;
	
	СтоимостьХраненияЗаОдниСутки = Константы.СтоимостьХранения.Получить();
	
	//Если услуги предоставлялись в выходной день, тогда расчет должен производится по двойному тарифу
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	СУММА(ВЫБОР
		|			КОГДА ПроизводственныйКалендарь.ВидДня = ЗНАЧЕНИЕ(Перечисление.ВидыДнейПроизводственногоКалендаря.Рабочий)
		|				ТОГДА &СтоимостьХранения
		|			ИНАЧЕ 2 * &СтоимостьХранения
		|		КОНЕЦ) КАК Стоимость
		|ИЗ
		|	РегистрСведений.ПроизводственныйКалендарь КАК ПроизводственныйКалендарь,
		|	Константа.СтоимостьХранения КАК СтоимостьХранения
		|ГДЕ
		|	ПроизводственныйКалендарь.Дата МЕЖДУ &ДатаНачало И &ДатаКонец";
	
	Запрос.УстановитьПараметр("ДатаКонец", ДатаУбытия);
	Запрос.УстановитьПараметр("ДатаНачало", ДатаПрибытия);
	Запрос.УстановитьПараметр("СтоимостьХранения", СтоимостьХраненияЗаОдниСутки);

	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Если ВыборкаДетальныеЗаписи.Следующий() Тогда 
		ОбщаяСтоимостьХранения = ВыборкаДетальныеЗаписи.Стоимость;
	КонецЕсли;
	
	Возврат ОбщаяСтоимостьХранения
	
КонецФункции 

Функция  ПолучитьОбщуюСтоимостьОбработки(ДатаПрибытия, ДатаУбытия, ТипГрузовогоМеста) 
	
	ОбщаяСтоимостьОбработки = 0;
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	СУММА(ВЫБОР
		|			КОГДА ПроизводственныйКалендарь.ВидДня = ЗНАЧЕНИЕ(Перечисление.ВидыДнейПроизводственногоКалендаря.Рабочий)
		|				ТОГДА ТарифыНаОбработку.Стоимость
		|			ИНАЧЕ 2 * ТарифыНаОбработку.Стоимость
		|		КОНЕЦ) КАК Стоимость
		|ИЗ
		|	РегистрСведений.ПроизводственныйКалендарь КАК ПроизводственныйКалендарь
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.ТарифыНаОбработку КАК ТарифыНаОбработку
		|		ПО (НАЧАЛОПЕРИОДА(ПроизводственныйКалендарь.Дата, МЕСЯЦ) = ТарифыНаОбработку.Период)
		|ГДЕ
		|	ПроизводственныйКалендарь.Дата МЕЖДУ &ДатаНачало И &ДатаКонец
		|	И ТарифыНаОбработку.ТипГрузовогоМеста = &ТипГрузовогоМеста";
	
	Запрос.УстановитьПараметр("ДатаКонец", ДатаУбытия);
	Запрос.УстановитьПараметр("ДатаНачало", НачалоДня(ДатаПрибытия));
	Запрос.УстановитьПараметр("ТипГрузовогоМеста", ТипГрузовогоМеста);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Если ВыборкаДетальныеЗаписи.Следующий() Тогда
		ОбщаяСтоимостьОбработки = ВыборкаДетальныеЗаписи.Стоимость;
	КонецЕсли;
	
	Возврат ОбщаяСтоимостьОбработки	
	
КонецФункции


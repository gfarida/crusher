# Общее описание

Этот пример показывает фаззинг dll библиотек, написанных на C#.

# Создание проекта - обертки

В системе должен быть установлен пакет SDK и среда выполнения ASP.NET Core. Ссылка на инструкцию по их установке для
всех поддерживаемых операционных систем - https://docs.microsoft.com/ru-ru/dotnet/core/install/.
Необходимо выбрать свою ОС, её версию и последовательно выполнить все шаги установки.

Если у Вас Ubuntu, то перейдите по данной ссылке (https://docs.microsoft.com/ru-ru/dotnet/core/install/linux-ubuntu) и выполните установку
пакета и среды выполнения для нужной версии ОС.
Для фаззинга dll библиотеки необходимо создать проект-обертку.

### Этапы создания:
1. В корне проекта-обертки `target/AngleSharp.Fuzz*` лежит библиотека `AngleSharp.dll`, которую хотим пофаззить. В файле `*.csproj` прописана соответствующая зависимость для ее видимости.

2. В файле `Program.cs` в качестве аргумента функции `Run` передается лямбда-функция (см. пример ниже), в которой вызывается функция `Parse()` из тестируемой библиотеки `AngleSharp`.


Если фаззинг происходит через **stdin**, то работаем со `stream`. Файл Program.cs выглядит так:

```c++
using System;
using AngleSharp.Parser.Html;
using AngleSharp;
using SharpFuzz;

namespace AngleSharp.Fuzz
{
	public class Program
	{
		public static void Main(string[] args)
		{
			Fuzzer.OutOfProcess.Run(stream =>
			{
				try
				{
					new HtmlParser().Parse(stream);	
				}
				catch (InvalidOperationException) { }
			});
		}
	}
}

```

А если через **файл**, то работаем с первым аргументом командной строки - `args[0]`. Ниже показан файл Program.cs:

```c++
using System;
using AngleSharp.Parser.Html;
using AngleSharp;
using SharpFuzz;

namespace AngleSharp.Fuzz
{
	public class Program
	{
		public static void Main(string[] args)
		{
			Fuzzer.OutOfProcess.Run(stream =>
			{
				try
				{
					var html = File.ReadAllText(args[0]);
					new HtmlParser().Parse(html);
				}
				catch (InvalidOperationException) { }
			});
		}
	}
}

```


В проект-обертку `AngleSharp.Fuzz*` в качестве зависимости также добавлена библиотека `SharpFuzz.dll` версии 1.6.2 (необходимые строки прописаны в файле `*.csproj`). В ней находится функция для запуска нашего проекта-обертки `AngleSharp.Fuzz*` и он собирается как dll файл.

# Фаззинг

1. Произведите инструментацию библиотеки `AngleSharp.dll` для фаззинга. Соберите проект-обертку `target/AngleSharp.Fuzz*`. Для этого запустите скрипт `./instrument.sh`, который принимает один аргумент - путь до `dotnet`.

2. Находясь в данной директории, запустите скрипт `./fuzz-stdin.sh` для фаззинга библиотеки через **stdin** и `./fuzz-file.sh` для фаззинга через **файл**;
они принимают два аргумента - путь до `fuzz_manager` и до исполняемого файла`dotnet`, установленного в Вашей системе. `dotnet` обычно находится здесь (точнее, символическая
ссылка на исполняемый файл dotnet): /usr/bin/dotnet.

3. Запустите в другом терминале `UI` фаззера (укажите актуальные пути):

```shell
/path/to/crusher/bin_x86-64/ui --outdir /path/to/out
```

Как только будут найдены аварийные завершения, значение поля `unique_crashes` (в окне `UI` - наверху справа) станет ненулевым.

Прервать фаззинг (в первом терминале, `Ctrl + С`)

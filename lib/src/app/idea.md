- maybe instead of runApp use run and call them something else than App => Program/Runner
- (reserve the name App for widgets)
- => use runApp only if running a widget 🤯(otherwise would have to be wrapped in a WidgetProgram)
- 	Application, 	Program,	Main,	Runner,	Bootstrap,	Engine,	Core


- only baseclasses that can be used: SequentialApp, ViewportApp, LoggerApp (=> therefore everything can be done by mixing them)
- are sealed so that no ugly interface from outside
- all widgets (which are also apps) are based on the ViewportApp<Object>

- root app is always a SequentialApp

- apps cannot be exited prematurely as they give back ReturnType,
  but they can be wrapped in an ExitProgram which can be exited and then return null (extends App<ReturnType?>)
- for example a ask can be wrapped that way and then if the ask doesnt give back fast enough it can be exited and return null
```dart
class App<ReturnType> {...}

class ExampleApp extends SequetialApp<void> {
  FutureOr<void> start() async {
    log('App started');
    await loader(Duration(seconds: 3));
    log('Loading complete');
    
    await runApp(DurationApp(seconds: 3));
  }
}

void main() async {
  log(ExampleLogo());
  
  await runApp(ExampleApp());
  
  await runApp();

  final taskResult = await loader(_longTaskFnc); /* the same: */ await runApp(LoaderApp(_longTaskFnc));
  
  log('Loading complete');

  final input = await ask('Enter something: '); /* the same: */ final input = await runApp(AskApp(prompt: 'Enter something: '));
}
```
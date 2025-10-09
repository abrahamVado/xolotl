import 'api.dart';
import 'session_service.dart';

//1.- sessionService instancia única compartida en toda la app.
final SessionService sessionService = SessionService();

//2.- apiService reutiliza la sesión para adjuntar tokens automáticamente.
final ApiService apiService = ApiService(session: sessionService);

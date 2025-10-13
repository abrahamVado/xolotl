import 'api.dart';
import 'folio_repository.dart';
import 'session_service.dart';

//1.- sessionService instancia única compartida en toda la app.
final SessionService sessionService = SessionService();

//2.- folioRepository centraliza el almacenamiento de folios por sesión activa.
final FolioRepository folioRepository = FolioRepository(session: sessionService);

//3.- apiService reutiliza la sesión para adjuntar tokens automáticamente.
final ApiService apiService =
    ApiService(session: sessionService, folios: folioRepository);

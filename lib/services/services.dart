import 'api.dart';
import 'folio_repository.dart';
import 'location_service.dart';
import 'session_service.dart';

//1.- sessionService instancia única compartida en toda la app.
final SessionService sessionService = SessionService();

//2.- folioRepository centraliza el almacenamiento de folios por sesión activa.
final FolioRepository folioRepository = FolioRepository(session: sessionService);

//3.- locationService centraliza las consultas de GPS compartidas en la app.
final LocationService locationService = LocationService();

//4.- apiService reutiliza la sesión para adjuntar tokens automáticamente.
final ApiService apiService =
    ApiService(session: sessionService, folios: folioRepository);

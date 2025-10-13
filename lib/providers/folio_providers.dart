import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/folio_repository.dart';
import '../services/services.dart';

//1.- folioRepositoryProvider expone la instancia configurable para la UI.
final folioRepositoryProvider = Provider<FolioRepository>((ref) {
  return folioRepository;
});

//2.- FolioListNotifier coordina lecturas asincrónicas del repositorio.
class FolioListNotifier extends AutoDisposeAsyncNotifier<List<FolioEntry>> {
  @override
  Future<List<FolioEntry>> build() async {
    final repository = ref.watch(folioRepositoryProvider);
    return repository.loadForCurrentSession();
  }

  //3.- refresh vuelve a consultar el repositorio y actualiza el estado global.
  Future<void> refresh() async {
    final repository = ref.read(folioRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.loadForCurrentSession);
  }

  //4.- upsert sincroniza el repositorio con una entrada nueva o actualizada.
  Future<void> upsert(FolioEntry entry) async {
    final repository = ref.read(folioRepositoryProvider);
    await repository.saveForCurrentSession(entry);
    final current = await repository.loadForCurrentSession();
    state = AsyncData(current);
  }
}

//5.- folioListProvider ofrece la lista observable dentro de la jerarquía de widgets.
final folioListProvider =
    AutoDisposeAsyncNotifierProvider<FolioListNotifier, List<FolioEntry>>(
  FolioListNotifier.new,
);

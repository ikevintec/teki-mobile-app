part of 'product_form.dart';

// ─── Manejo de imágenes del formulario de producto ───────────────────────────

mixin ProductFormImages on StateNotifier<ProductFormState> {
  Ref get ref;
  ImageRepository get imageRepository;

  /// numeroOrden de la imagen por defecto (o -1 si no hay imágenes).
  int _slotPrincipal(List<ProductImageDraft> imgs) {
    for (final d in imgs) {
      if (d.porDefecto) return d.numeroOrden;
    }
    return imgs.isNotEmpty ? imgs.first.numeroOrden : -1;
  }

  /// Reasigna `numeroOrden` = posición para mantener las imágenes siempre
  /// contiguas y en orden, y garantiza que exista exactamente una por defecto.
  List<ProductImageDraft> _normalizar(List<ProductImageDraft> imgs) {
    final hayDefault = imgs.any((d) => d.porDefecto);
    return [
      for (int i = 0; i < imgs.length; i++)
        imgs[i].copyWith(
          numeroOrden: i,
          porDefecto: hayDefault ? imgs[i].porDefecto : i == 0,
        ),
    ];
  }

  /// Agrega una imagen nueva (archivo local) al final de la lista y la deja
  /// seleccionada. La primera imagen del producto se marca automáticamente
  /// como por defecto; las siguientes no.
  void addImagen(String path, XFile? file) {
    if (state.imagenes.length >= ProductFormNotifier.maxImagenes) return;
    final nuevos = _normalizar([
      ...state.imagenes,
      ProductImageDraft(
        url: path,
        file: file,
        numeroOrden: state.imagenes.length,
        porDefecto: state.imagenes.isEmpty,
      ),
    ]);
    state = state.copyWith(
      imagenes: nuevos,
      imagenSeleccionadaSlot: nuevos.length - 1,
    );
  }

  /// Cambia la posición de una imagen (arrastrar en la tira). Reasigna el
  /// `numeroOrden` según el nuevo orden y conserva cuál está seleccionada.
  void reordenarImagenes(int oldIndex, int newIndex) {
    final imgs = [...state.imagenes];
    if (oldIndex < 0 || oldIndex >= imgs.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0) newIndex = 0;
    if (newIndex >= imgs.length) newIndex = imgs.length - 1;

    final seleccionada = state.imagenSeleccionadaSlot;
    final movido = imgs.removeAt(oldIndex);
    imgs.insert(newIndex, movido);
    // Nueva posición del que estaba seleccionado (numeroOrden aún original).
    final idxSel = imgs.indexWhere((d) => d.numeroOrden == seleccionada);
    state = state.copyWith(
      imagenes: _normalizar(imgs),
      imagenSeleccionadaSlot: idxSel >= 0 ? idxSel : seleccionada,
    );
  }

  /// Marca qué imagen está seleccionada (la que se muestra en el círculo).
  void setImagenSeleccionada(int numeroOrden) {
    state = state.copyWith(imagenSeleccionadaSlot: numeroOrden);
  }

  /// Elimina la imagen del slot indicado. Las restantes se recompactan (sin
  /// huecos) y se garantiza una por defecto. Ajusta también la selección.
  void removeImagen(int numeroOrden) {
    final restantes = state.imagenes
        .where((d) => d.numeroOrden != numeroOrden)
        .toList();
    int nuevoSel;
    if (state.imagenSeleccionadaSlot == numeroOrden) {
      nuevoSel = restantes.isNotEmpty ? 0 : -1;
    } else {
      final idx = restantes
          .indexWhere((d) => d.numeroOrden == state.imagenSeleccionadaSlot);
      nuevoSel = idx >= 0 ? idx : (restantes.isNotEmpty ? 0 : -1);
    }
    state = state.copyWith(
      imagenes: _normalizar(restantes),
      imagenSeleccionadaSlot: nuevoSel,
    );
  }

  /// Marca la imagen del slot indicado como la por defecto (desmarca el resto).
  void setImagenPorDefecto(int numeroOrden) {
    state = state.copyWith(
      imagenes: state.imagenes
          .map((d) => d.copyWith(porDefecto: d.numeroOrden == numeroOrden))
          .toList(),
    );
  }

  /// Reemplaza (o crea) la imagen actualmente seleccionada. Lo usa el círculo
  /// superior: al elegir una nueva foto sustituye la seleccionada; con `path`
  /// vacío la quita. Si aún no hay imágenes, crea la primera (por defecto).
  void setImagenSeleccionadaFile(String path, XFile? file) {
    if (path.isEmpty) {
      final sel = state.imagenSeleccionada;
      if (sel != null) removeImagen(sel.numeroOrden);
      return;
    }
    final imgs = [...state.imagenes];
    final idx =
        imgs.indexWhere((d) => d.numeroOrden == state.imagenSeleccionadaSlot);
    if (idx >= 0) {
      imgs[idx] = ProductImageDraft(
        url: path,
        file: file,
        numeroOrden: imgs[idx].numeroOrden,
        porDefecto: imgs[idx].porDefecto,
      );
      state = state.copyWith(imagenes: imgs);
    } else {
      addImagen(path, file);
    }
  }

  /// Convierte las `imagenes` del producto (backend) en borradores editables.
  /// Solo conserva las no eliminadas, limita a [ProductFormNotifier.maxImagenes] y normaliza el
  /// `numeroOrden` a la posición (0..n) para mapear a los slots de la UI.
  /// Garantiza que exista exactamente una imagen por defecto.
  List<ProductImageDraft> _draftsFromProduct(List<ProductImage>? imgs) {
    if (imgs == null) return const [];
    final activas = imgs.where((i) => i.eliminado != true).toList()
      ..sort((a, b) => (a.numeroOrden ?? 0).compareTo(b.numeroOrden ?? 0));
    final visibles = activas.take(ProductFormNotifier.maxImagenes).toList();
    final tieneDefault = visibles.any((i) => i.porDefecto == true);
    final drafts = <ProductImageDraft>[];
    for (int i = 0; i < visibles.length; i++) {
      final img = visibles[i];
      drafts.add(ProductImageDraft(
        id: img.id,
        url: img.imagen ?? '',
        numeroOrden: i,
        porDefecto: tieneDefault ? (img.porDefecto == true) : i == 0,
      ));
    }
    return drafts;
  }

  /// Construye el campo `imagenes` (lista) que espera el API a partir de los
  /// borradores actuales (ya con URL resuelta en [loadImagen]):
  /// - Cada imagen conservada o nueva se envía con su `numeroOrden` y su
  ///   marca `porDefecto` (solo una es `true`).
  /// - Las imágenes que existían en el backend y ya no están en el form se
  ///   envían con `eliminado: true` (conservando su `id`).
  List<ProductImage> _buildImagenes() {
    final existentes = state.product.imagenes ?? [];
    final actuales = state.imagenes;
    final idsActuales =
        actuales.map((d) => d.id).where((id) => id != null).toSet();

    final result = <ProductImage>[];

    // Imágenes del backend que ya no están en el form: marcarlas eliminadas.
    for (final img in existentes) {
      if (img.id != null &&
          img.eliminado != true &&
          !idsActuales.contains(img.id)) {
        result.add(img.copyWith(eliminado: true));
      }
    }

    // Imágenes actuales (conservadas o nuevas).
    for (final d in actuales) {
      result.add(ProductImage(
        id: d.id,
        imagen: d.url,
        numeroOrden: d.numeroOrden,
        porDefecto: d.porDefecto,
        eliminado: false,
      ));
    }

    return result;
  }

  /// Sube las imágenes nuevas (las que tienen archivo local) y reemplaza su
  /// URL local por la remota devuelta por el backend.
  Future<void> loadImagen() async {
    if (!state.imagenes.any((d) => d.file != null)) return;
    final idCompany = ref.read(sesionProvider).company!.id;
    final actualizadas = <ProductImageDraft>[];
    for (final d in state.imagenes) {
      if (d.file != null) {
        final imageResponse = await imageRepository.getImageUrl(
            idCompany!, d.file!.path, d.file!.name);
        actualizadas.add(ProductImageDraft(
          id: null,
          url: imageResponse.url,
          numeroOrden: d.numeroOrden,
          porDefecto: d.porDefecto,
        ));
      } else {
        actualizadas.add(d);
      }
    }
    state = state.copyWith(imagenes: actualizadas);
  }
}

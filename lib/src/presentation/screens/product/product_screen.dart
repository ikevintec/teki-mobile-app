import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/presentation/screens/product/sections/general_section.dart';
import 'package:teki_app/src/presentation/screens/product/sections/precios_section.dart';
import 'package:teki_app/src/presentation/screens/product/sections/product_not_found_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/floating_aciton_button/custom_floating_action_button.dart';
import 'package:teki_app/src/presentation/widgets/loader/screen_loader.dart';
import 'package:teki_app/src/providers/formularios/product_form.dart';
import 'package:teki_app/src/providers/products/product.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/notifications.dart';

class ProductScreen extends HookConsumerWidget {
  final int? productId;

  const ProductScreen({super.key, this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(productProvider);
    final controller = useTabController(initialLength: 2);
    final selectedTabIndex = useState(0);

    final generalFormKey = useMemoized(() => GlobalKey<FormState>());
    final preciosFormKey = useMemoized(() => GlobalKey<FormState>());

    final isLoaded = useRef(false);

    useEffect(() {
      if (!isLoaded.value) {
        Future.microtask(() async {
          await ref.read(productProvider.notifier).loadMainData();

          final currencies = ref.read(productProvider).currencies!;
          final units = ref.read(productProvider).unitCodes!;

          if (productId != null) {
            await ref.read(productProvider.notifier).loadProduct(productId!);
          }

          final product = productId != null ? ref.read(productProvider).product! : Product();
          ref.read(productFormProvider.notifier).loadDataFromProduct(
                product,
                currencies,
                units,
              );
        });
        isLoaded.value = true;
      }
      return null;
    }, []);

    if (provider.isLoading ?? true) {
      return const ScreenLoader(message: 'Cargando Producto...');
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(
          navigateName:
              productId == null ? "Crear Producto" : "Editar Producto"
        ),
      ),
      body: provider.isError == true
          ? const ProductNotFoundScreen()
          : IndexedStack(
              index: selectedTabIndex.value,
              children: [
                ProductGeneralSection(formKey: generalFormKey),
                ProductPreciosSection(formKey: preciosFormKey),
              ],
            ),
      bottomNavigationBar: CurvedNavigationBar(
        index: selectedTabIndex.value,
        height: 60.0,
        backgroundColor: Colors.transparent, // Fondo detrás de la barra
        color: ColorSchema.primaryColor, // Color de la barra (fondo)
        buttonBackgroundColor:
            ColorSchema.primaryColor, // Botón/tab seleccionado
        animationDuration: Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        items: const <Widget>[
          Icon(Icons.description, size: 25, color: Colors.white),
          Icon(Icons.attach_money, size: 25, color: Colors.white),
        ],
        onTap: (index) {
          selectedTabIndex.value = index;
          controller.animateTo(index);
        },
      ),
      floatingActionButton: provider.isError == true
          ? null
          : CustomFloatingActionButton(
              iconData: productId != null ? Icons.edit : Icons.save,
              onPressed: () {
                final generalValid =
                    generalFormKey.currentState?.validate() ?? false;
                final preciosValid =
                    preciosFormKey.currentState?.validate() ?? false;

                if (!generalValid) {
                  selectedTabIndex.value = 0;
                  errorNotification(
                      'Completa los campos requeridos en "General"');
                  return;
                }

                if (!preciosValid) {
                  selectedTabIndex.value = 1;
                  errorNotification(
                      'Completa los campos requeridos en "Precios"');
                  return;
                }
                if (productId != null) {
                  ref.read(productFormProvider.notifier).updateProduct();
                  return;
                }
                ref.read(productFormProvider.notifier).createProduct();
              },
            ),
    );
  }
}

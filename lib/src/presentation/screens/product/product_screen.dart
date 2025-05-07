import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

          final product = ref.read(productProvider).product!;
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
              productId == null ? "Crear Producto" : "Editar Producto",
        ),
      ),
      body: provider.isError == true
          ? const ProductNotFoundScreen()
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: controller,
                    onTap: (index) => selectedTabIndex.value = index,
                    labelColor: ColorSchema.primaryColor,
                    indicatorColor: ColorSchema.primaryColor,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: "General"),
                      Tab(text: "Precios"),
                    ],
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: selectedTabIndex.value,
                    children: [
                      ProductGeneralSection(formKey: generalFormKey),
                      ProductPreciosSection(formKey: preciosFormKey),
                    ],
                  ),
                ),
              ],
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
                  controller.animateTo(0); // 🔁 sincroniza con TabBar
                  errorNotification(
                      'Completa los campos requeridos en "General"');
                  return;
                }

                if (!preciosValid) {
                  selectedTabIndex.value = 1;
                  controller.animateTo(1); // 🔁 sincroniza con TabBar
                  errorNotification(
                      'Completa los campos requeridos en "Precios"');
                  return;
                }

                successNotification('Formulario válido');
              },
            ),
    );
  }
}

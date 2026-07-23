import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/floating_action_button/custom_floating_action_button.dart';
import 'package:teki_app/src/presentation/screens/customer/widgets/customer_filters_modal.dart';
import 'package:teki_app/src/presentation/screens/customer/customer_sections/customer_details_screen.dart';
import 'package:teki_app/src/presentation/screens/customer/customer_sections/create_customer_section.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/customers/customers.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

class CustomerMainScreen extends ConsumerStatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  ConsumerState<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends ConsumerState<CustomerMainScreen> {
  final controller = SidebarXController(selectedIndex: 1, extended: true);
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customersProvider.notifier).clearState();
      ref.read(customersProvider.notifier).loadFirstPage();
    });

    _scrollController.addListener(() {
      final state = ref.read(customersProvider);
      final reachedEnd = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300;

      if (reachedEnd && state.paginacion && !state.isLoading!) {
        ref.read(customersProvider.notifier).loadMorePages();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CustomerFiltersModal(
          onApplyFilters: () {
            setState(() {});
          },
        ),
      ),
    );
  }

  void _clearFilters() {
    ref.read(customersProvider.notifier).clearState();
    ref.read(customersProvider.notifier).loadFirstPage();
    setState(() {});
  }

  bool _hasActiveFilters() {
    final state = ref.read(customersProvider);
    return (state.filtro?.isNotEmpty == true) ||
        (state.telefono?.isNotEmpty == true) ||
        (state.email?.isNotEmpty == true);
  }

  void _reloadCustomers() {
    ref.read(customersProvider.notifier).clearState();
    ref.read(customersProvider.notifier).loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sesionProvider, (prev, next) {
      if (next.office?.id != prev?.office?.id) {
        _reloadCustomers();
      }
    });

    // final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _key,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Clientes",
          onSettingsReturn: _reloadCustomers,
        ),
      ),
      body: Container(
        color: Colors.white70,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Clientes (${ref.watch(customersProvider).customers?.length ?? 0})',
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF2D3748),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.filter_alt_outlined,
                            color: Colors.blue,
                            size: 20,
                          ),
                          onPressed: _showFiltersModal,
                        ),
                      ),
                      if (_hasActiveFilters()) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.cleaning_services_outlined,
                              color: Colors.orange,
                              size: 20,
                            ),
                            onPressed: _clearFilters,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildCustomersList())
          ],
        ),
      ),
      floatingActionButton:
          ref.watch(sesionProvider).hasPermission('CLIENTES_CREAR')
              ? const CustomFloatingActionButton(
                  buttonName: "Crear Cliente",
                  routeName: AppRoutes.addCustomer)
              : null,
    );
  }

  Widget _buildCustomersList() {
    final customersState = ref.watch(customersProvider);
    final customers = customersState.customers ?? [];
    final isLoading = customersState.isLoading ?? false;

    final isInitialLoad = isLoading && customers.isEmpty;

    if (isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (customers.isEmpty) {
      return const Center(
        child: Text(
          "No hay clientes por mostrar.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: customers.length + (customersState.hasMore == true ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == customers.length && customersState.hasMore == true) {
          final state = ref.read(customersProvider);
          if (!state.isLoading!) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(customersProvider.notifier).loadMorePages();
            });
          }
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final customer = customers[index];
        return _buildCustomerCard(customer);
      },
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: ColorSchema.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.razonSocial ?? 'Sin nombre',
                        style: GoogleFonts.raleway(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (customer.tipoDocumento?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          formatTipoDocumento(customer.tipoDocumento ?? ''),
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (customer.numeroDocumento?.isNotEmpty == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: ColorSchema.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      customer.numeroDocumento!,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((customer.email?.isNotEmpty == true) ||
                    (customer.telefono?.isNotEmpty == true) ||
                    (customer.direccionCompleta?.isNotEmpty == true))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (customer.email?.isNotEmpty == true) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 14,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    customer.email!,
                                    style: GoogleFonts.roboto(
                                      color: const Color(0xFF6B7280),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (customer.telefono?.isNotEmpty == true ||
                                customer.direccionCompleta?.isNotEmpty == true)
                              const SizedBox(height: 6),
                          ],
                          if (customer.telefono?.isNotEmpty == true) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  customer.telefono!,
                                  style: GoogleFonts.roboto(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            if (customer.direccionCompleta?.isNotEmpty == true)
                              const SizedBox(height: 6),
                          ],
                          if (customer.direccionCompleta?.isNotEmpty ==
                              true) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    customer.direccionCompleta!,
                                    style: GoogleFonts.roboto(
                                      color: const Color(0xFF6B7280),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        Get.to(() => CustomerDetailsScreen(customer: customer));
                      },
                      icon: Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: ColorSchema.primaryColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Get.to(
                            () => AddCustomerSection(customerId: customer.id));
                      },
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

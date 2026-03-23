import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/utils/formats.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Detalles del Cliente",
        ),
      ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildInfoSection("Información Personal", [
                _buildInfoItem("Razón Social", customer.razonSocial),
                _buildInfoItem("Tipo de Documento", formatTipoDocumento(customer.tipoDocumento ?? '')),
                _buildInfoItem("Número de Documento", customer.numeroDocumento),
              ]),
              const SizedBox(height: 16),
              _buildInfoSection("Información de Contacto", [
                _buildInfoItem("Email", customer.email, icon: Icons.email_outlined),
                _buildInfoItem("Teléfono", customer.telefono, icon: Icons.phone_outlined),
                _buildInfoItem("Dirección", customer.direccionCompleta, icon: Icons.location_on_outlined),
              ]),
              const SizedBox(height: 16),
              _buildInfoSection("Información Adicional", [
                _buildInfoItem("Estado", customer.estado == true ? "Activo" : "Inactivo"),
                _buildInfoItem("Fecha de Nacimiento", _formatDate(customer.fechaNacimiento)),
                _buildInfoItem("Género", customer.genero),
                _buildInfoItem("Giro", customer.giro),
                _buildInfoItem("Referido", customer.referido),
                _buildInfoItem("Expediente", customer.expediente),
                _buildInfoItem("Por Defecto", customer.porDefecto == true ? "Sí" : "No"),
              ]),
              const SizedBox(height: 16),
              _buildInfoSection("Información de Ubicación", [
                _buildInfoItem("Tipo de Dirección", customer.tipoDireccion),
                _buildInfoItem("Dirección", customer.direccion),
                _buildInfoItem("Número", customer.numero),
                _buildInfoItem("Número de Departamento", customer.numeroDepartamento),
                _buildInfoItem("Referencia", customer.referencia),
                _buildInfoItem("Código de Departamento", customer.codigoDepartamento),
                _buildInfoItem("Código de Provincia", customer.codigoProvincia),
                _buildInfoItem("Código de Distrito", customer.codigoDistrito),
                _buildInfoItem("Código de Ciudad", customer.codigoCiudad),
                if (customer.latitud != null && customer.longitud != null)
                  _buildInfoItem("Coordenadas", "${customer.latitud}, ${customer.longitud}"),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.person,
                color: Colors.blue.shade600,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.razonSocial ?? 'Sin nombre',
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (customer.numeroDocumento?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        customer.numeroDocumento!,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    final filteredItems = items.where((item) => item != const SizedBox.shrink()).toList();
    
    if (filteredItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.raleway(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ...filteredItems,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value, {IconData? icon}) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
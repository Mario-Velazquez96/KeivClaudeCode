@isTest
public class TestDataFactory {

    public static Account createAccount(String name) {
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }

    public static Proveedor__c createProveedor(String nombre, Boolean requiereOC) {
        Proveedor__c prov = new Proveedor__c(
            Name = nombre,
            Activo__c = true,
            Requiere_Orden_Compra__c = requiereOC
        );
        insert prov;
        return prov;
    }

    public static Cotizacion__c createCotizacion(Id cuentaId, String condicionPago, Integer diasCredito) {
        Cotizacion__c cot = new Cotizacion__c(
            Cuenta__c = cuentaId,
            Fecha__c = Date.today(),
            Moneda__c = 'MXN',
            Tipo_Cambio__c = 1,
            Condicion_Pago__c = condicionPago,
            Dias_Credito__c = diasCredito,
            Estatus__c = 'Borrador'
        );
        insert cot;
        return cot;
    }

    public static Partida_Cotizacion__c createPartidaCotizacion(Id cotizacionId, Id proveedorId,
            Decimal cantidad, Decimal costoUnitario, Decimal precioUnitario) {
        Partida_Cotizacion__c pc = new Partida_Cotizacion__c(
            Cotizacion__c = cotizacionId,
            Proveedor__c = proveedorId,
            Descripcion__c = 'Producto de prueba',
            Cantidad__c = cantidad,
            Unidad__c = 'Pieza',
            Costo_Unitario__c = costoUnitario,
            Precio_Unitario__c = precioUnitario
        );
        insert pc;
        return pc;
    }

    public static Remision__c createRemision(Id cotizacionId) {
        Remision__c rem = new Remision__c(
            Cotizacion__c = cotizacionId,
            Fecha__c = Date.today(),
            Estatus_Entrega__c = 'Pendiente'
        );
        insert rem;
        return rem;
    }

    public static Partida_Remision__c createPartidaRemision(Id remisionId, Id partidaCotizacionId, Decimal cantidadEntregada) {
        Partida_Remision__c pr = new Partida_Remision__c(
            Remision__c = remisionId,
            Partida_Cotizacion__c = partidaCotizacionId,
            Cantidad_Entregada__c = cantidadEntregada
        );
        insert pr;
        return pr;
    }

    public static Aportacion_Socio__c createAportacion(Id cotizacionId, String socio, Decimal montoInversion) {
        Aportacion_Socio__c ap = new Aportacion_Socio__c(
            Cotizacion__c = cotizacionId,
            Socio__c = socio,
            Monto_Inversion__c = montoInversion
        );
        insert ap;
        return ap;
    }

    public static Pago__c createPago(Id cotizacionId, Decimal monto) {
        Pago__c p = new Pago__c(
            Cotizacion__c = cotizacionId,
            Fecha__c = Date.today(),
            Monto__c = monto,
            Metodo_Pago__c = 'Transferencia'
        );
        insert p;
        return p;
    }
}

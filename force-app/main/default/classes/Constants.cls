public class Constants {
    public static final Decimal IVA_RATE = 0.16;

    // Cotizacion Status
    public static final String COT_STATUS_BORRADOR = 'Borrador';
    public static final String COT_STATUS_ENVIADA = 'Enviada';
    public static final String COT_STATUS_ACEPTADA = 'Aceptada';
    public static final String COT_STATUS_RECHAZADA = 'Rechazada';
    public static final String COT_STATUS_EN_PROCESO = 'En Proceso';
    public static final String COT_STATUS_ENTREGADA = 'Entregada';
    public static final String COT_STATUS_COBRADA = 'Cobrada';
    public static final String COT_STATUS_CANCELADA = 'Cancelada';

    // Condicion de Pago
    public static final String PAGO_CONTADO = 'Contado';
    public static final String PAGO_CREDITO = 'Credito';

    // Estatus Proveedor
    public static final String PROV_PENDIENTE = 'Pendiente';
    public static final String PROV_COTIZADO = 'Cotizado';
    public static final String PROV_CONFIRMADO = 'Confirmado';
    public static final String PROV_EN_TRANSITO = 'En Transito';
    public static final String PROV_RECIBIDO = 'Recibido';

    // Estatus Orden de Compra
    public static final String OC_BORRADOR = 'Borrador';
    public static final String OC_ENVIADA = 'Enviada';
    public static final String OC_CONFIRMADA = 'Confirmada';
    public static final String OC_PARCIAL = 'Parcialmente Recibida';
    public static final String OC_RECIBIDA = 'Recibida';
    public static final String OC_CANCELADA = 'Cancelada';
}

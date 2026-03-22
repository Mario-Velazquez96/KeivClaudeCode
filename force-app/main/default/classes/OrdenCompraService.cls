public with sharing class OrdenCompraService {

    @AuraEnabled
    public static List<Id> generarOrdenesCompra(Id cotizacionId) {
        List<Partida_Cotizacion__c> partidas = [
            SELECT Id, Proveedor__c, Proveedor__r.Requiere_Orden_Compra__c,
                   Descripcion__c, Cantidad__c, Unidad__c, Costo_Unitario__c
            FROM Partida_Cotizacion__c
            WHERE Cotizacion__c = :cotizacionId
            AND Proveedor__c != null
        ];

        Map<Id, List<Partida_Cotizacion__c>> partidasByProveedor = new Map<Id, List<Partida_Cotizacion__c>>();
        for (Partida_Cotizacion__c pc : partidas) {
            if (pc.Proveedor__r.Requiere_Orden_Compra__c != true) continue;

            if (!partidasByProveedor.containsKey(pc.Proveedor__c)) {
                partidasByProveedor.put(pc.Proveedor__c, new List<Partida_Cotizacion__c>());
            }
            partidasByProveedor.get(pc.Proveedor__c).add(pc);
        }

        List<Orden_Compra__c> ordenesCompra = new List<Orden_Compra__c>();
        for (Id proveedorId : partidasByProveedor.keySet()) {
            ordenesCompra.add(new Orden_Compra__c(
                Cotizacion__c = cotizacionId,
                Proveedor__c = proveedorId,
                Fecha__c = Date.today(),
                Estatus__c = Constants.OC_BORRADOR
            ));
        }

        insert ordenesCompra;

        List<Partida_Orden_Compra__c> partidasOC = new List<Partida_Orden_Compra__c>();
        for (Orden_Compra__c oc : ordenesCompra) {
            List<Partida_Cotizacion__c> partidasProveedor = partidasByProveedor.get(oc.Proveedor__c);
            for (Partida_Cotizacion__c pc : partidasProveedor) {
                partidasOC.add(new Partida_Orden_Compra__c(
                    Orden_Compra__c = oc.Id,
                    Partida_Cotizacion__c = pc.Id,
                    Descripcion__c = pc.Descripcion__c,
                    Cantidad__c = pc.Cantidad__c,
                    Unidad__c = pc.Unidad__c,
                    Costo_Unitario__c = pc.Costo_Unitario__c
                ));
            }
        }

        insert partidasOC;

        List<Id> ocIds = new List<Id>();
        for (Orden_Compra__c oc : ordenesCompra) {
            ocIds.add(oc.Id);
        }
        return ocIds;
    }
}

public with sharing class OrdenCompraService {

    @AuraEnabled
    public static List<Id> generarOrdenesCompra(Id cotizacionId) {
        // 1. Get all partidas that require OC
        List<Partida_Cotizacion__c> partidas = [
            SELECT Id, Proveedor__c, Proveedor__r.Requiere_Orden_Compra__c,
                   Descripcion__c, Cantidad__c, Unidad__c, Costo_Unitario__c
            FROM Partida_Cotizacion__c
            WHERE Cotizacion__c = :cotizacionId
            AND Proveedor__c != null
            AND Proveedor__r.Requiere_Orden_Compra__c = true
        ];

        // 2. Get existing OCs and their partidas for this cotizacion
        Map<Id, Orden_Compra__c> existingOCsByProveedor = new Map<Id, Orden_Compra__c>();
        Set<Id> existingPartidaCotizacionIds = new Set<Id>();

        List<Orden_Compra__c> existingOCs = [
            SELECT Id, Proveedor__c,
                (SELECT Id, Partida_Cotizacion__c FROM Partidas_Orden_Compra__r)
            FROM Orden_Compra__c
            WHERE Cotizacion__c = :cotizacionId
        ];

        for (Orden_Compra__c oc : existingOCs) {
            existingOCsByProveedor.put(oc.Proveedor__c, oc);
            for (Partida_Orden_Compra__c poc : oc.Partidas_Orden_Compra__r) {
                existingPartidaCotizacionIds.add(poc.Partida_Cotizacion__c);
            }
        }

        // 3. Group NEW partidas (not already in an OC) by proveedor
        Map<Id, List<Partida_Cotizacion__c>> newPartidasByProveedor = new Map<Id, List<Partida_Cotizacion__c>>();
        for (Partida_Cotizacion__c pc : partidas) {
            if (existingPartidaCotizacionIds.contains(pc.Id)) continue;

            if (!newPartidasByProveedor.containsKey(pc.Proveedor__c)) {
                newPartidasByProveedor.put(pc.Proveedor__c, new List<Partida_Cotizacion__c>());
            }
            newPartidasByProveedor.get(pc.Proveedor__c).add(pc);
        }

        if (newPartidasByProveedor.isEmpty()) {
            return new List<Id>();
        }

        // 4. Create new OCs only for proveedores that don't have one yet
        List<Orden_Compra__c> newOCs = new List<Orden_Compra__c>();
        for (Id proveedorId : newPartidasByProveedor.keySet()) {
            if (!existingOCsByProveedor.containsKey(proveedorId)) {
                newOCs.add(new Orden_Compra__c(
                    Cotizacion__c = cotizacionId,
                    Proveedor__c = proveedorId,
                    Fecha__c = Date.today(),
                    Estatus__c = Constants.OC_BORRADOR
                ));
            }
        }

        if (!newOCs.isEmpty()) {
            insert newOCs;
            for (Orden_Compra__c oc : newOCs) {
                existingOCsByProveedor.put(oc.Proveedor__c, oc);
            }
        }

        // 5. Create partida OC lines linked to the correct OC (new or existing)
        List<Partida_Orden_Compra__c> partidasOC = new List<Partida_Orden_Compra__c>();
        for (Id proveedorId : newPartidasByProveedor.keySet()) {
            Orden_Compra__c oc = existingOCsByProveedor.get(proveedorId);
            for (Partida_Cotizacion__c pc : newPartidasByProveedor.get(proveedorId)) {
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

        if (!partidasOC.isEmpty()) {
            insert partidasOC;
        }

        // 6. Return all affected OC Ids
        Set<Id> affectedOCIds = new Set<Id>();
        for (Id proveedorId : newPartidasByProveedor.keySet()) {
            affectedOCIds.add(existingOCsByProveedor.get(proveedorId).Id);
        }
        return new List<Id>(affectedOCIds);
    }
}

public with sharing class OrdenCompraController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getEstadoOrdenes(Id cotizacionId) {
        // Get all partidas that require OC
        List<Partida_Cotizacion__c> partidas = [
            SELECT Id, Proveedor__c, Proveedor__r.Name,
                   Proveedor__r.Requiere_Orden_Compra__c,
                   Descripcion__c, Cantidad__c, Costo_Unitario__c
            FROM Partida_Cotizacion__c
            WHERE Cotizacion__c = :cotizacionId
            AND Proveedor__c != null
            AND Proveedor__r.Requiere_Orden_Compra__c = true
        ];

        // Get partidas already linked to an OC
        Set<Id> partidasEnOC = new Set<Id>();
        List<Partida_Orden_Compra__c> existingPOCs = [
            SELECT Partida_Cotizacion__c
            FROM Partida_Orden_Compra__c
            WHERE Orden_Compra__r.Cotizacion__c = :cotizacionId
        ];
        for (Partida_Orden_Compra__c poc : existingPOCs) {
            partidasEnOC.add(poc.Partida_Cotizacion__c);
        }

        // Build response grouped by proveedor, only showing pending partidas
        Map<Id, Map<String, Object>> proveedoresMap = new Map<Id, Map<String, Object>>();
        Integer totalPartidas = 0;
        Integer partidasCubiertas = 0;

        for (Partida_Cotizacion__c pc : partidas) {
            totalPartidas++;
            if (partidasEnOC.contains(pc.Id)) {
                partidasCubiertas++;
                continue;
            }

            if (!proveedoresMap.containsKey(pc.Proveedor__c)) {
                Map<String, Object> provData = new Map<String, Object>();
                provData.put('proveedorId', pc.Proveedor__c);
                provData.put('proveedorName', pc.Proveedor__r.Name);
                provData.put('partidas', new List<Map<String, Object>>());
                provData.put('total', 0.0);
                proveedoresMap.put(pc.Proveedor__c, provData);
            }

            Map<String, Object> provData = proveedoresMap.get(pc.Proveedor__c);
            List<Map<String, Object>> partidasList = (List<Map<String, Object>>) provData.get('partidas');

            Map<String, Object> partidaData = new Map<String, Object>();
            partidaData.put('id', pc.Id);
            partidaData.put('descripcion', pc.Descripcion__c);
            partidaData.put('cantidad', pc.Cantidad__c);
            partidaData.put('costoUnitario', pc.Costo_Unitario__c);
            partidasList.add(partidaData);

            Decimal currentTotal = (Decimal) provData.get('total');
            Decimal lineCost = (pc.Cantidad__c != null ? pc.Cantidad__c : 0) *
                              (pc.Costo_Unitario__c != null ? pc.Costo_Unitario__c : 0);
            provData.put('total', currentTotal + lineCost);
        }

        Map<String, Object> result = new Map<String, Object>();
        result.put('proveedoresPendientes', proveedoresMap.values());
        result.put('totalPartidas', totalPartidas);
        result.put('partidasCubiertas', partidasCubiertas);
        result.put('todasCubiertas', totalPartidas > 0 && partidasCubiertas == totalPartidas);
        return result;
    }

    @AuraEnabled
    public static List<Id> generarOrdenes(Id cotizacionId) {
        return OrdenCompraService.generarOrdenesCompra(cotizacionId);
    }
}

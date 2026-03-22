public with sharing class CotizacionService {

    public static void recalcularTotales(Set<Id> cotizacionIds) {
        if (cotizacionIds == null || cotizacionIds.isEmpty()) {
            return;
        }

        Map<Id, Cotizacion__c> cotizacionesMap = new Map<Id, Cotizacion__c>();
        for (Id cotId : cotizacionIds) {
            cotizacionesMap.put(cotId, new Cotizacion__c(
                Id = cotId,
                Subtotal__c = 0,
                Costo_Total__c = 0,
                IVA__c = 0,
                Total__c = 0
            ));
        }

        for (AggregateResult ar : [
            SELECT Cotizacion__c,
                   SUM(Total_Linea__c) sumVenta,
                   SUM(Costo_Total_Linea__c) sumCosto
            FROM Partida_Cotizacion__c
            WHERE Cotizacion__c IN :cotizacionIds
            GROUP BY Cotizacion__c
        ]) {
            Id cotId = (Id) ar.get('Cotizacion__c');
            Decimal sumVenta = (Decimal) ar.get('sumVenta');
            Decimal sumCosto = (Decimal) ar.get('sumCosto');

            if (sumVenta == null) sumVenta = 0;
            if (sumCosto == null) sumCosto = 0;

            Cotizacion__c cot = cotizacionesMap.get(cotId);
            cot.Subtotal__c = sumVenta;
            cot.Costo_Total__c = sumCosto;
            cot.IVA__c = sumVenta * Constants.IVA_RATE;
            cot.Total__c = sumVenta + (sumVenta * Constants.IVA_RATE);
        }

        update cotizacionesMap.values();
    }

    public static void recalcularMontoPagado(Set<Id> cotizacionIds) {
        if (cotizacionIds == null || cotizacionIds.isEmpty()) {
            return;
        }

        Map<Id, Cotizacion__c> cotizacionesMap = new Map<Id, Cotizacion__c>();
        for (Id cotId : cotizacionIds) {
            cotizacionesMap.put(cotId, new Cotizacion__c(
                Id = cotId,
                Monto_Pagado__c = 0
            ));
        }

        for (AggregateResult ar : [
            SELECT Cotizacion__c, SUM(Monto__c) totalPagado
            FROM Pago__c
            WHERE Cotizacion__c IN :cotizacionIds
            GROUP BY Cotizacion__c
        ]) {
            Id cotId = (Id) ar.get('Cotizacion__c');
            Decimal totalPagado = (Decimal) ar.get('totalPagado');
            if (totalPagado == null) totalPagado = 0;

            cotizacionesMap.get(cotId).Monto_Pagado__c = totalPagado;
        }

        update cotizacionesMap.values();
    }
}

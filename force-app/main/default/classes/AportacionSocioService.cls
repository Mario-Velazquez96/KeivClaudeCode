public with sharing class AportacionSocioService {

    public static void recalcularDistribucion(Set<Id> cotizacionIds) {
        if (cotizacionIds == null || cotizacionIds.isEmpty()) {
            return;
        }

        Map<Id, Decimal> utilidadByCotizacion = new Map<Id, Decimal>();
        for (Cotizacion__c cot : [
            SELECT Id, Utilidad__c
            FROM Cotizacion__c
            WHERE Id IN :cotizacionIds
        ]) {
            utilidadByCotizacion.put(cot.Id, cot.Utilidad__c != null ? cot.Utilidad__c : 0);
        }

        Map<Id, List<Aportacion_Socio__c>> aportacionesByCotizacion = new Map<Id, List<Aportacion_Socio__c>>();
        for (Aportacion_Socio__c ap : [
            SELECT Id, Cotizacion__c, Monto_Inversion__c, Porcentaje_Inversion__c, Monto_Utilidad__c
            FROM Aportacion_Socio__c
            WHERE Cotizacion__c IN :cotizacionIds
        ]) {
            if (!aportacionesByCotizacion.containsKey(ap.Cotizacion__c)) {
                aportacionesByCotizacion.put(ap.Cotizacion__c, new List<Aportacion_Socio__c>());
            }
            aportacionesByCotizacion.get(ap.Cotizacion__c).add(ap);
        }

        List<Aportacion_Socio__c> toUpdate = new List<Aportacion_Socio__c>();

        for (Id cotId : cotizacionIds) {
            List<Aportacion_Socio__c> aportaciones = aportacionesByCotizacion.get(cotId);
            if (aportaciones == null || aportaciones.isEmpty()) continue;

            Decimal totalInversion = 0;
            for (Aportacion_Socio__c ap : aportaciones) {
                totalInversion += (ap.Monto_Inversion__c != null ? ap.Monto_Inversion__c : 0);
            }

            if (totalInversion <= 0) continue;

            Decimal utilidad = utilidadByCotizacion.get(cotId);
            if (utilidad == null) utilidad = 0;

            for (Aportacion_Socio__c ap : aportaciones) {
                Decimal inversion = ap.Monto_Inversion__c != null ? ap.Monto_Inversion__c : 0;
                Decimal porcentaje = inversion / totalInversion;
                Decimal montoUtilidad = utilidad * porcentaje;

                toUpdate.add(new Aportacion_Socio__c(
                    Id = ap.Id,
                    Porcentaje_Inversion__c = porcentaje * 100,
                    Monto_Utilidad__c = montoUtilidad
                ));
            }
        }

        if (!toUpdate.isEmpty()) {
            AportacionSocioTriggerHandler.skipRecalculation = true;
            update toUpdate;
            AportacionSocioTriggerHandler.skipRecalculation = false;
        }
    }
}

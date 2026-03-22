public with sharing class EntregaService {

    public static void recalcularCantidadesEntregadas(Set<Id> partidaCotizacionIds) {
        if (partidaCotizacionIds == null || partidaCotizacionIds.isEmpty()) {
            return;
        }

        Map<Id, Partida_Cotizacion__c> partidasMap = new Map<Id, Partida_Cotizacion__c>();
        for (Id pId : partidaCotizacionIds) {
            partidasMap.put(pId, new Partida_Cotizacion__c(
                Id = pId,
                Cantidad_Entregada__c = 0
            ));
        }

        for (AggregateResult ar : [
            SELECT Partida_Cotizacion__c, SUM(Cantidad_Entregada__c) totalEntregado
            FROM Partida_Remision__c
            WHERE Partida_Cotizacion__c IN :partidaCotizacionIds
            GROUP BY Partida_Cotizacion__c
        ]) {
            Id partidaId = (Id) ar.get('Partida_Cotizacion__c');
            Decimal totalEntregado = (Decimal) ar.get('totalEntregado');
            if (totalEntregado == null) totalEntregado = 0;

            partidasMap.get(partidaId).Cantidad_Entregada__c = totalEntregado;
        }

        update partidasMap.values();
    }

    public static void verificarEntregaCompleta(Set<Id> cotizacionIds) {
        if (cotizacionIds == null || cotizacionIds.isEmpty()) {
            return;
        }

        Map<Id, List<Partida_Cotizacion__c>> partidasByCotizacion = new Map<Id, List<Partida_Cotizacion__c>>();
        for (Partida_Cotizacion__c pc : [
            SELECT Id, Cotizacion__c, Cantidad__c, Cantidad_Entregada__c
            FROM Partida_Cotizacion__c
            WHERE Cotizacion__c IN :cotizacionIds
        ]) {
            if (!partidasByCotizacion.containsKey(pc.Cotizacion__c)) {
                partidasByCotizacion.put(pc.Cotizacion__c, new List<Partida_Cotizacion__c>());
            }
            partidasByCotizacion.get(pc.Cotizacion__c).add(pc);
        }

        List<Cotizacion__c> cotizacionesToUpdate = new List<Cotizacion__c>();

        Map<Id, Cotizacion__c> cotizaciones = new Map<Id, Cotizacion__c>([
            SELECT Id, Fecha_Entrega_Completa__c
            FROM Cotizacion__c
            WHERE Id IN :cotizacionIds
        ]);

        for (Id cotId : cotizacionIds) {
            List<Partida_Cotizacion__c> partidas = partidasByCotizacion.get(cotId);
            Cotizacion__c cot = cotizaciones.get(cotId);

            if (cot == null) continue;

            Boolean todasEntregadas = true;

            if (partidas == null || partidas.isEmpty()) {
                todasEntregadas = false;
            } else {
                for (Partida_Cotizacion__c pc : partidas) {
                    if (pc.Cantidad_Entregada__c == null || pc.Cantidad_Entregada__c < pc.Cantidad__c) {
                        todasEntregadas = false;
                        break;
                    }
                }
            }

            if (todasEntregadas && cot.Fecha_Entrega_Completa__c == null) {
                cotizacionesToUpdate.add(new Cotizacion__c(
                    Id = cotId,
                    Fecha_Entrega_Completa__c = Date.today(),
                    Estatus__c = Constants.COT_STATUS_ENTREGADA
                ));
            } else if (!todasEntregadas && cot.Fecha_Entrega_Completa__c != null) {
                cotizacionesToUpdate.add(new Cotizacion__c(
                    Id = cotId,
                    Fecha_Entrega_Completa__c = null
                ));
            }
        }

        if (!cotizacionesToUpdate.isEmpty()) {
            update cotizacionesToUpdate;
        }
    }
}

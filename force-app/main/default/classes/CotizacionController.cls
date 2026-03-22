public with sharing class CotizacionController {

    @AuraEnabled(cacheable=true)
    public static List<Partida_Cotizacion__c> getPartidasCotizacion(Id cotizacionId) {
        return [
            SELECT Id, Name, Descripcion__c, Cantidad__c, Unidad__c,
                   Costo_Unitario__c, Precio_Unitario__c, Margen_Porcentaje__c,
                   Total_Linea__c, Costo_Total_Linea__c, Proveedor__c,
                   Proveedor__r.Name, Estatus_Proveedor__c,
                   Cantidad_Entregada__c, Cantidad_Pendiente__c, Entrega_Completa__c
            FROM Partida_Cotizacion__c
            WHERE Cotizacion__c = :cotizacionId
            ORDER BY Name ASC
        ];
    }

    @AuraEnabled
    public static Partida_Cotizacion__c savePartida(Partida_Cotizacion__c partida) {
        upsert partida;
        return partida;
    }

    @AuraEnabled
    public static void deletePartida(Id partidaId) {
        delete [SELECT Id FROM Partida_Cotizacion__c WHERE Id = :partidaId];
    }

    @AuraEnabled(cacheable=true)
    public static List<Remision__c> getRemisiones(Id cotizacionId) {
        return [
            SELECT Id, Name, Fecha__c, Firmada__c, Notas__c,
                   (SELECT Id, Partida_Cotizacion__c, Partida_Cotizacion__r.Descripcion__c,
                           Cantidad_Entregada__c
                    FROM Partidas_Remision__r)
            FROM Remision__c
            WHERE Cotizacion__c = :cotizacionId
            ORDER BY Fecha__c DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPartidasPendientesEntrega(Id cotizacionId) {
        List<Partida_Cotizacion__c> partidas = [
            SELECT Id, Name, Descripcion__c, Cantidad__c, Unidad__c,
                   Cantidad_Entregada__c, Cantidad_Pendiente__c, Entrega_Completa__c
            FROM Partida_Cotizacion__c
            WHERE Cotizacion__c = :cotizacionId
            ORDER BY Name ASC
        ];

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Partida_Cotizacion__c pc : partidas) {
            Decimal pendiente = pc.Cantidad_Pendiente__c != null ? pc.Cantidad_Pendiente__c : 0;
            Map<String, Object> item = new Map<String, Object>();
            item.put('id', pc.Id);
            item.put('name', pc.Name);
            item.put('descripcion', pc.Descripcion__c);
            item.put('cantidad', pc.Cantidad__c);
            item.put('unidad', pc.Unidad__c);
            item.put('entregada', pc.Cantidad_Entregada__c != null ? pc.Cantidad_Entregada__c : 0);
            item.put('pendiente', pendiente);
            item.put('completa', pc.Entrega_Completa__c);
            result.add(item);
        }
        return result;
    }

    @AuraEnabled
    public static Id crearRemisionConPartidas(Id cotizacionId, String partidasJson) {
        List<Object> rawList = (List<Object>) JSON.deserializeUntyped(partidasJson);

        if (rawList == null || rawList.isEmpty()) {
            throw new AuraHandledException('Debe seleccionar al menos una partida para la remision.');
        }

        // Validate quantities before creating anything
        Set<Id> partidaIds = new Set<Id>();
        Map<Id, Decimal> cantidadesSolicitadas = new Map<Id, Decimal>();
        for (Object rawItem : rawList) {
            Map<String, Object> pd = (Map<String, Object>) rawItem;
            Id partidaId = (Id) pd.get('partidaCotizacionId');
            Decimal cantidad = pd.get('cantidad') != null ? Decimal.valueOf(String.valueOf(pd.get('cantidad'))) : 0;
            if (cantidad <= 0) {
                throw new AuraHandledException('La cantidad debe ser mayor a cero.');
            }
            partidaIds.add(partidaId);
            cantidadesSolicitadas.put(partidaId, cantidad);
        }

        Map<Id, Partida_Cotizacion__c> partidasMap = new Map<Id, Partida_Cotizacion__c>([
            SELECT Id, Name, Cantidad__c, Cantidad_Entregada__c, Cantidad_Pendiente__c
            FROM Partida_Cotizacion__c
            WHERE Id IN :partidaIds
        ]);

        for (Id pId : cantidadesSolicitadas.keySet()) {
            Partida_Cotizacion__c pc = partidasMap.get(pId);
            if (pc == null) {
                throw new AuraHandledException('Partida no encontrada.');
            }
            Decimal pendiente = pc.Cantidad_Pendiente__c != null ? pc.Cantidad_Pendiente__c : 0;
            Decimal solicitada = cantidadesSolicitadas.get(pId);
            if (solicitada > pendiente) {
                throw new AuraHandledException(
                    'La cantidad para ' + pc.Name + ' (' + solicitada.setScale(2) +
                    ') excede la cantidad pendiente (' + pendiente.setScale(2) + ').'
                );
            }
        }

        // Create remision
        Remision__c remision = new Remision__c(
            Cotizacion__c = cotizacionId,
            Fecha__c = Date.today()
        );
        insert remision;

        // Create partida remision lines
        List<Partida_Remision__c> lineas = new List<Partida_Remision__c>();
        for (Object rawItem : rawList) {
            Map<String, Object> pd = (Map<String, Object>) rawItem;
            lineas.add(new Partida_Remision__c(
                Remision__c = remision.Id,
                Partida_Cotizacion__c = (Id) pd.get('partidaCotizacionId'),
                Cantidad_Entregada__c = Decimal.valueOf(String.valueOf(pd.get('cantidad')))
            ));
        }
        insert lineas;

        return remision.Id;
    }

    @AuraEnabled(cacheable=true)
    public static List<Aportacion_Socio__c> getAportaciones(Id cotizacionId) {
        return [
            SELECT Id, Name, Socio__c, Monto_Inversion__c,
                   Porcentaje_Inversion__c, Monto_Utilidad__c, Retorno_Total__c
            FROM Aportacion_Socio__c
            WHERE Cotizacion__c = :cotizacionId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Pago__c> getPagos(Id cotizacionId) {
        return [
            SELECT Id, Name, Fecha__c, Monto__c, Metodo_Pago__c, Notas__c
            FROM Pago__c
            WHERE Cotizacion__c = :cotizacionId
            ORDER BY Fecha__c DESC
        ];
    }
}

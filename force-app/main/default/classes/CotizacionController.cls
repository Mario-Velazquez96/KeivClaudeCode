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
            SELECT Id, Name, Fecha__c, Estatus_Entrega__c, Firmada__c, Notas__c,
                   (SELECT Id, Partida_Cotizacion__c, Partida_Cotizacion__r.Descripcion__c,
                           Cantidad_Entregada__c
                    FROM Partidas_Remision__r)
            FROM Remision__c
            WHERE Cotizacion__c = :cotizacionId
            ORDER BY Fecha__c DESC
        ];
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

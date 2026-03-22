public class CreditoVencidoSchedulable implements Schedulable {

    public void execute(SchedulableContext sc) {
        List<Cotizacion__c> cotizacionesVencidas = [
            SELECT Id, Name, Cuenta__c, Cuenta__r.Name, Total__c,
                   Saldo_Pendiente__c, Fecha_Vencimiento_Credito__c, OwnerId
            FROM Cotizacion__c
            WHERE Credito_Vencido__c = true
            LIMIT 200
        ];

        List<Task> tareasCobranza = new List<Task>();

        for (Cotizacion__c cot : cotizacionesVencidas) {
            Date hoy = Date.today();

            List<Task> tareasExistentes = [
                SELECT Id FROM Task
                WHERE WhatId = :cot.Id
                AND Subject LIKE 'Credito vencido%'
                AND ActivityDate = :hoy
                LIMIT 1
            ];

            if (tareasExistentes.isEmpty()) {
                tareasCobranza.add(new Task(
                    Subject = 'Credito vencido - ' + cot.Name,
                    Description = 'La cotizacion ' + cot.Name + ' para el cliente ' +
                                  cot.Cuenta__r.Name + ' tiene un saldo pendiente de $' +
                                  String.valueOf(cot.Saldo_Pendiente__c) +
                                  '. Fecha de vencimiento: ' +
                                  String.valueOf(cot.Fecha_Vencimiento_Credito__c),
                    ActivityDate = hoy,
                    WhatId = cot.Id,
                    OwnerId = cot.OwnerId,
                    Priority = 'High',
                    Status = 'Not Started'
                ));
            }
        }

        if (!tareasCobranza.isEmpty()) {
            insert tareasCobranza;
        }
    }
}

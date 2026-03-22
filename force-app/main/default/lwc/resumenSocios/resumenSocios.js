import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAportaciones from '@salesforce/apex/CotizacionController.getAportaciones';

const COLUMNS = [
    { label: 'Socio', fieldName: 'Socio__c', type: 'text' },
    { label: 'Inversion', fieldName: 'Monto_Inversion__c', type: 'currency' },
    { label: '% Inversion', fieldName: 'Porcentaje_Inversion__c', type: 'percent', typeAttributes: { minimumFractionDigits: 2 } },
    { label: 'Utilidad', fieldName: 'Monto_Utilidad__c', type: 'currency' },
    { label: 'Retorno Total', fieldName: 'Retorno_Total__c', type: 'currency' }
];

export default class ResumenSocios extends NavigationMixin(LightningElement) {
    @api recordId;
    columns = COLUMNS;

    @wire(getAportaciones, { cotizacionId: '$recordId' })
    aportaciones;

    get hasAportaciones() {
        return this.aportaciones.data && this.aportaciones.data.length > 0;
    }

    handleNewAportacion() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Aportacion_Socio__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `Cotizacion__c=${this.recordId}`
            }
        });
    }
}

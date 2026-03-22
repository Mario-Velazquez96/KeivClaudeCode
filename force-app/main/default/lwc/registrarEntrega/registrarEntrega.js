import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRemisiones from '@salesforce/apex/CotizacionController.getRemisiones';

export default class RegistrarEntrega extends NavigationMixin(LightningElement) {
    @api recordId;

    @wire(getRemisiones, { cotizacionId: '$recordId' })
    remisiones;

    get hasRemisiones() {
        return this.remisiones.data && this.remisiones.data.length > 0;
    }

    handleNewRemision() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Remision__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `Cotizacion__c=${this.recordId}`
            }
        });
    }
}

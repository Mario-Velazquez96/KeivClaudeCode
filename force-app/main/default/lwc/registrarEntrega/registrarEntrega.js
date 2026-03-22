import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import getRemisiones from '@salesforce/apex/CotizacionController.getRemisiones';
import getPartidasPendientesEntrega from '@salesforce/apex/CotizacionController.getPartidasPendientesEntrega';
import crearRemisionConPartidas from '@salesforce/apex/CotizacionController.crearRemisionConPartidas';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RegistrarEntrega extends LightningElement {
    @api recordId;
    showNewModal = false;
    isCreating = false;
    selectedPartidas = {};
    _wiredRemisiones;
    _wiredPartidas;

    @wire(getRemisiones, { cotizacionId: '$recordId' })
    wiredRemisiones(result) {
        this._wiredRemisiones = result;
    }

    @wire(getPartidasPendientesEntrega, { cotizacionId: '$recordId' })
    wiredPartidas(result) {
        this._wiredPartidas = result;
    }

    get remisiones() {
        return this._wiredRemisiones?.data || [];
    }

    get hasRemisiones() {
        return this.remisiones.length > 0;
    }

    get partidasPendientes() {
        return (this._wiredPartidas?.data || []).filter(p => p.pendiente > 0);
    }

    get hasPartidasPendientes() {
        return this.partidasPendientes.length > 0;
    }

    get todasEntregadas() {
        const partidas = this._wiredPartidas?.data || [];
        return partidas.length > 0 && partidas.every(p => p.completa);
    }

    get partidasParaModal() {
        return this.partidasPendientes.map(p => ({
            ...p,
            cantidadSeleccionada: this.selectedPartidas[p.id] || 0,
            isSelected: this.selectedPartidas[p.id] > 0,
            maxCantidad: p.pendiente
        }));
    }

    get hasSelectedPartidas() {
        return Object.values(this.selectedPartidas).some(v => v > 0);
    }

    get isCreateDisabled() {
        return this.isCreating || !this.hasSelectedPartidas;
    }

    handleNewRemision() {
        this.selectedPartidas = {};
        this.showNewModal = true;
    }

    handleCloseModal() {
        this.showNewModal = false;
        this.selectedPartidas = {};
    }

    handleCantidadChange(event) {
        const partidaId = event.target.dataset.id;
        const maxPendiente = parseFloat(event.target.dataset.max);
        let value = parseFloat(event.target.value) || 0;

        if (value < 0) {
            value = 0;
        }
        if (value > maxPendiente) {
            value = maxPendiente;
            event.target.value = value;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Cantidad ajustada',
                message: `La cantidad no puede exceder lo pendiente (${maxPendiente}).`,
                variant: 'warning'
            }));
        }

        this.selectedPartidas = { ...this.selectedPartidas, [partidaId]: value };
    }

    handleEntregarTodo(event) {
        const partidaId = event.target.dataset.id;
        const maxPendiente = parseFloat(event.target.dataset.max);
        this.selectedPartidas = { ...this.selectedPartidas, [partidaId]: maxPendiente };
    }

    async handleCrearRemision() {
        const partidasToSend = [];
        for (const [partidaId, cantidad] of Object.entries(this.selectedPartidas)) {
            if (cantidad > 0) {
                partidasToSend.push({
                    partidaCotizacionId: partidaId,
                    cantidad: cantidad
                });
            }
        }

        if (partidasToSend.length === 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Seleccione al menos una partida con cantidad mayor a cero.',
                variant: 'error'
            }));
            return;
        }

        this.isCreating = true;
        try {
            await crearRemisionConPartidas({
                cotizacionId: this.recordId,
                partidasJson: JSON.stringify(partidasToSend)
            });
            this.showNewModal = false;
            this.selectedPartidas = {};
            this.dispatchEvent(new ShowToastEvent({
                title: 'Remision Creada',
                message: `Se creo la remision con ${partidasToSend.length} partida(s).`,
                variant: 'success'
            }));
            await refreshApex(this._wiredRemisiones);
            await refreshApex(this._wiredPartidas);
            getRecordNotifyChange([{ recordId: this.recordId }]);
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'Error al crear la remision.',
                variant: 'error'
            }));
        } finally {
            this.isCreating = false;
        }
    }
}

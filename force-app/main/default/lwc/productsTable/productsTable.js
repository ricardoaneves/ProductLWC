import { LightningElement, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import queryProducts from "@salesforce/apex/ProductsController.queryProducts";
import updateFavorite from '@salesforce/apex/ProductsController.updateFavorite';
import fetch from '@salesforce/apex/ProductsController.fetch'

export default class ProductsTable extends LightningElement {

    products;
    pagedProducts = [];
    filteredProducts = [];
    total = 0;
    currentPage = 1;
    pageSize = 8;
    totalPages = 0;
    stockPerPage = 0;
    pricePerPage = 0;
    disablePrevious = true;
    disableNext = false;
    options = [];
    selected = [];
    onlyFavorites = false;
    nameSearch = undefined;
    brandSearch = undefined;
    isLoading = true;

    // Runs when the LWC is initialized
    connectedCallback(){

        this.loadData();

    }

    // Asynchronous method to load data and manage spinner
    async loadData(){

        try{

            // Spinner on
            this.isLoading = true;
            await fetch();

        } catch(error){

            console.error('Error in loadData:', error);

        } finally{

            // Spinner off
            this.isLoading = false;

        }
        
    }

    // Get products from Salesforce data
    @wire(queryProducts)
    wiredProducts({data, error}){

        if(data){

            this.products = data;
            this.filteredProducts = data;
            this.totalPages = Math.ceil(this.products.length / this.pageSize);
            this.updatePagedProducts();

            // Get unique category values
            const categorySet = new Set();
            data.forEach(product => {
                if (product.category) {
                    categorySet.add(product.category);
                }
            });

            // Convert Set to options array for lightning-checkbox-group
            this.options = [...categorySet].map(cat => {
                const label = cat
                .replace(/-/g, ' ')
                .replace(/^./, c => c.toUpperCase());
            
                return {
                    label: label,
                    value: cat
                };
            });

        } else if(error){
            console.error('Error fetching products: ', error);
        }
    };

    // Select which products will be shown in the page, due to pagination
    updatePagedProducts(){
        
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.totalPages = Math.ceil(this.filteredProducts.length / this.pageSize);
        this.pagedProducts = this.filteredProducts.slice(start, end);

        this.stockPerPage = 0;

        // Get the sum of the stocks of all products shown in the page
        this.pagedProducts.forEach(product => {

            const stock = product.stock || 0;
            this.stockPerPage += stock;

        });

        // Get the sum of the prices of all products shown in the page
        this.pricePerPage = 0;
        this.pagedProducts.forEach(product => {

            const price = parseFloat(product.price) || 0;
            this.pricePerPage += price;

        });

        this.pricePerPage = this.pricePerPage.toFixed(2);

        // Buttons visibility
        if(this.currentPage == 1){this.disablePrevious = true;} else{this.disablePrevious = false;}
        if(this.currentPage === this.totalPages){this.disableNext = true;} else{this.disableNext = false;}

    }

    // Handle next page click
    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePagedProducts();
        }
    }
    
    // Handle previous page click
    prevPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePagedProducts();
        }
    }

    // Handle add to card click
    handleAddToCart(event){

        console.log(event.target.dataset.price);
        const price = parseFloat(event.target.dataset.price) || 0;
        this.total += price;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Product added to cart!',
                message: 'Total value: ' + this.total.toFixed(2) + '€',
                variant: 'success',
                mode: 'dismissable'
            })
        );
    }

    // Handle favorite click
    toggleFavorite(event){

        const productId = event.currentTarget.dataset.id;
    
        this.pagedProducts = this.pagedProducts.map(prod =>{

            if(prod.id === productId){

                updateFavorite({productId, favorite: !prod.favorite})
                    .then(() => {
                        console.log(`Updated favorite to ${!prod.favorite}`);
                    })
                    .catch(error => {
                        console.error('Error updating favorite:', error);
                    });
    
                return {...prod, favorite: !prod.favorite};

            }
            return prod;
        });

        this.products = this.products.map(prod => {

            if(prod.id === productId) {
                return {...prod, favorite: !prod.favorite};
            }

            return prod;

        });

        this.applyFilters();

    }

    // Handle name filter
    handleNameChange(event){

        this.nameSearch = event.target.value.toLowerCase();
        console.log('this.nameSearch:', this.nameSearch);
        this.applyFilters();

    }

    // Handle brand filter
    handleBrandChange(event){

        this.brandSearch = event.target.value.toLowerCase();
        this.applyFilters();

    }

    // Handle categories filter
    handleCategoriesChange(event){

        this.selected = event.detail.value;
        this.applyFilters();

    }

    // Handle favorites filter
    handleFavoritesChange(event){

        this.onlyFavorites = event.target.checked;
        this.applyFilters();
    }

    // Apply all selected filter
    applyFilters(){

        let total = 0;
        this.currentPage = 1;
        this.filteredProducts = this.products;

        if(this.selected.length === 0){
            this.filteredProducts = this.products;
        } else{
            this.filteredProducts = this.filteredProducts.filter(prod =>
                this.selected.includes(prod.category)
            );
        }

        if(this.nameSearch != undefined){

            this.filteredProducts = this.filteredProducts.filter(prod =>
                prod.title && prod.title.toLowerCase().includes(this.nameSearch)
            );

        }

        if(this.brandSearch != undefined){

            this.filteredProducts = this.filteredProducts.filter(prod =>
                prod.title && prod.title.toLowerCase().includes(this.brandSearch)
            );

        }

        if(this.onlyFavorites){

            this.filteredProducts = this.filteredProducts.filter(prod => prod.favorite);

        }

        console.log('length', this.filteredProducts.length);

        let tempProds = [];
        for(let product of this.filteredProducts){

            const price = parseFloat(product.price) || 0;
            if(total + price > 10000){
                break;
            }
            total += price;
            tempProds.push(product);
            console.log('product', product);
            
        }

        this.filteredProducts = tempProds;

        this.updatePagedProducts();

    }
}
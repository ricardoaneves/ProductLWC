public with sharing class ProductsController{

    public class DummyJsonResponse{

        public List<ProductWrapper> products;

    }
    
    public class ProductWrapper{

        public String id;
        public String title;
        public String brand;
        public String category;
        public Decimal price;
        public String sku;
        public Integer stock;
        public String thumbnail;

    }

    public class TokenWrapper{

        public String username;
        public String accessToken;

    }

    public class Product{

        @AuraEnabled public String id;
        @AuraEnabled public String title;
        @AuraEnabled public String brand;
        @AuraEnabled public String category;
        @AuraEnabled public Decimal price;
        @AuraEnabled public String sku;
        @AuraEnabled public Integer stock;
        @AuraEnabled public Boolean favorite;
        @AuraEnabled public String thumbnail;

    }

    // Get auth token
    public static String getToken(){

        String token = null;
        String url = 'https://dummyjson.com/auth/login';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody('{"username":"logant", "password":"logantpass"}');

        HttpResponse response = http.send(request);

        if(response.getStatusCode() == 200){

            TokenWrapper tokenWrapper = (TokenWrapper) JSON.deserialize(response.getBody(), TokenWrapper.class);
            token = tokenWrapper.accessToken;

            System.debug('tokenWrapper: ' + tokenWrapper);

        }

        return token;

    }

    // Get products from DummyJSON API
    public static DummyJsonResponse getProducts(String token){

        DummyJsonResponse res = new DummyJsonResponse();
        String url = 'https://dummyjson.com/products';
        String params = '?limit=0';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url + params);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + token);

        HttpResponse response = http.send(request);

        if(response.getStatusCode() == 200){

            res = (DummyJsonResponse) JSON.deserialize(response.getBody(), DummyJsonResponse.class);

        }

        return res;

    }

    // Insert products in Salesforce database if they do not exist, update them if they do
    public static Boolean insertProducts(List<ProductWrapper> products){

        Boolean success = true;
        List<Product2> prodsToUpsert = new List<Product2>();

        Schema.SObjectField dummyId = Product2.Fields.Dummy_Id__c;

        for(ProductWrapper prod : products){

            Product2 p = new Product2();
            p.Dummy_Id__c = prod.id;
            p.Name = prod.title;
            p.Brand__c = prod.brand;
            p.Category__c = prod.category;
            p.Price__c = prod.price;
            p.SKU__c = prod.sku;
            p.Stock__c = prod.stock;
            p.Image__c = prod.thumbnail;
            
            prodsToUpsert.add(p);

        }

        Database.UpsertResult[] results = Database.upsert(prodsToUpsert, dummyId, false);

        return success;

    }

    // Fetch products
    @AuraEnabled
    public static void fetch(){

        String token = getToken();

        DummyJsonResponse res = new DummyJsonResponse();
        res = getProducts(token);

        System.debug('res: ' + res);
        System.debug('res size: ' + res.products.size());

        Boolean success = insertProducts(res.products);

    }

    // Query products from Salesforce data to show in the page
    @AuraEnabled(cacheable=true)
    public static List<Product> queryProducts(){

        List<Product2> prods = new List<Product2>();
        prods = [SELECT Id, Dummy_Id__c, Name, Brand__c, Category__c, Price__c, SKU__c, Stock__c, Favorite__c, Image__c FROM Product2];

        List<Id> prodIds = new List<Id>();

        for(Product2 p : prods){
            prodIds.add(p.Id);
        }

        Map<Id, ContentDocumentLink> images = new Map<Id, ContentDocumentLink>();

        for(ContentDocumentLink cl : [SELECT Id, LinkedEntityId, ContentDocument.LatestPublishedVersion.VersionDataUrl FROM ContentDocumentLink WHERE LinkedEntityId IN :prodIds]){
            images.put(cl.LinkedEntityId, cl);
        }

        List<Product> res = new List<Product>();
        Map<String, Integer> categoryCounts = new Map<String, Integer>();

        for(Product2 p : prods){

            String category = p.Category__c;

            Integer count = 0;
            if(categoryCounts.containsKey(category)){

                count = categoryCounts.get(category);

            }

            if(count < 100){

                Product pr = new Product();
                pr.Id = p.Id;
                pr.title = p.Name;
                pr.brand = p.Brand__c;
                pr.category = p.Category__c;
                pr.price = p.Price__c;
                pr.sku = p.SKU__c;
                pr.favorite = p.Favorite__c;
                pr.stock = Integer.valueOf(p.Stock__c);
                if(images.containsKey(p.Id)){
                    pr.thumbnail = images.get(p.Id).ContentDocument.LatestPublishedVersion.VersionDataUrl;
                }

                res.add(pr);

                categoryCounts.put(category, count+1);

            }
        }

        System.debug('res: ' + res);

        return res;

    }

    // Update favorite field in product
    @AuraEnabled
    public static void updateFavorite(String productId, Boolean favorite){

        try{

            Product2 prod = [SELECT Id, Favorite__c FROM Product2 WHERE Id = :productId LIMIT 1];
            prod.Favorite__c = favorite;
            update prod;

        } catch(Exception e){

            throw new AuraHandledException('Error updating favorite: ' + e.getMessage());

        }
    }
}
@isTest
private class ProductsControllerTest{

    @TestSetup
    static void makeData(){
        
        Product2 prod1 = new Product2();
        prod1.Name = 'prod1';
        prod1.IsActive = true;
        prod1.SKU__c = 'prod1';
        prod1.Stock__c = 10;
        prod1.Image__c = 'https://cdn.dummyjson.com/products/images/beauty/Eyeshadow%20Palette%20with%20Mirror/thumbnail.png';
        
        insert prod1;

    }

    private class DummyProductsMock implements HttpCalloutMock{

        public HTTPResponse respond(HTTPRequest req){

            HttpResponse res = new HttpResponse();
            String jsonBody = '{"products":[{"id":"1","title":"prod1","brand":"b1","category":"c1","price":99.99,"sku":"sku1","stock":10,"thumbnail":"https://cdn.dummyjson.com/products/images/beauty/Eyeshadow%20Palette%20with%20Mirror/thumbnail.png"},{"id":"2","title":"prod2","brand":"b2","category":"c2","price":15.99,"sku":"sku2","stock":5,"thumbnail":"https://cdn.dummyjson.com/products/images/beauty/Red%20Lipstick/thumbnail.png"}]}';
            res.setBody(jsonBody);
            res.setStatusCode(200);

            return res;

        }
    }

    @isTest
    static void fetchTest(){

        Test.setMock(HttpCalloutMock.class, new DummyProductsMock());

        Test.startTest();
            ProductsController.fetch();
        Test.stopTest();

        List<Product2> prods = new List<Product2>();
        prods = [SELECT Id, Dummy_Id__c, Name FROM Product2];

        System.Assert.areEqual(3, prods.size());

    }

    @isTest
    static void queryProductsTest(){

        List<ProductsController.Product> res = new List<ProductsController.Product>();

        Test.startTest();
            res = ProductsController.queryProducts();
        Test.stopTest();

        System.Assert.areEqual(1, res.size());

    }

    @isTest
    static void updateFavoriteTest(){

        Product2 prod = [SELECT Id, Dummy_Id__c, Name, Favorite__c FROM Product2 LIMIT 1];

        Test.startTest();
            ProductsController.updateFavorite(prod.Id, true);
        Test.stopTest();
        
        Product2 res =  [SELECT Id, Dummy_Id__c, Name, Favorite__c FROM Product2 WHERE Id =: prod.Id LIMIT 1];
        System.Assert.areEqual(true, res.Favorite__c);

    }
}
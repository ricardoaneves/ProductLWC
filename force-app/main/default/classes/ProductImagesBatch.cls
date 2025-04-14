public class ProductImagesBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext BC){

        // Get all products with images
        return Database.getQueryLocator([
            SELECT Id, Name, Image__c 
            FROM Product2 
            WHERE Image__c != null
        ]);

    }

    public void execute(Database.BatchableContext BC, List<SObject> scope){

        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
        Map<Id, Id> productToContentDocMap = new Map<Id, Id>();
        Map<Id, Blob> productToBlob = new Map<Id, Blob>();

        for (Product2 product : (List<Product2>) scope){

            try{

                // Get image from thumbnail
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint(product.Image__c);
                req.setMethod('GET');

                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200){

                    // Convert image to blob
                    Blob image = res.getBodyAsBlob();

                    ContentVersion cv = new ContentVersion();
                    cv.Title = product.Name;
                    cv.PathOnClient = '/' + product.Name + '.png';
                    cv.IsMajorVersion = true;
                    cv.VersionData = image;
                    contentVersionsToInsert.add(cv);

                    productToBlob.put(product.Id, image);

                }
                
            } catch(Exception e){

                System.debug('Error processing product ' + product.Id + ': ' + e.getMessage());

            }
        }

        if (!contentVersionsToInsert.isEmpty()){

            insert contentVersionsToInsert;

            List<ContentDocumentLink> links = new List<ContentDocumentLink>();

            for (ContentVersion cv : contentVersionsToInsert){

                // Not an issue because the batch should run for one Product at a time
                List<ContentVersion> cvs = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

                for(Product2 product : (List<Product2>)scope){

                    if(cv.VersionData == productToBlob.get(product.Id)){

                        // Link image to the Product
                        ContentDocumentLink link = new ContentDocumentLink();
                        link.ContentDocumentId = cvs.get(0).ContentDocumentId;
                        link.LinkedEntityId = product.Id;
                        link.ShareType = 'V';
                        link.Visibility = 'AllUsers';
                        links.add(link);

                        break;

                    }
                }
            }

            if(!links.isEmpty()){

                insert links;

            }
        }
    }

    public void finish(Database.BatchableContext BC){

    }
}
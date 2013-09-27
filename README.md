---

# salesforce-metadata.js

---

salesforce-metadata.js is a library for accessing Salesforce Metadata API from a web browser.

### dependency
Salesforce.com AJAX Connector  (AJAX Toolkit)
[https://login.salesforce.com/soap/ajax/28.0/connection.js](https://login.salesforce.com/soap/ajax/28.0/connection.js)


### usage
    <script type="text/javascript">
        __sfdcSessionId = "{!$API.Session_ID}";
    </script>
    <script type="text/javascript" src="/soap/ajax/28.0/connection.js"></script>
    <script type="text/javascript" src="{!URLFOR($Resource.metadatajs)}"></script>


## Sample Code

### Utility Calls

#### describeMetadata
    sforce.metadata.describeMetadata(function (response) {
        console.log(response);
    });

#### listMetadata
    sforce.metadata.listMetadata(
        {queries: [{type: 'ApexPage'}, {type: 'Layout'}], asOfVersion: 26},
        function (results) {
            console.log(results);
        }
    );


### CRUD-Based Calls

#### checkStatus
    function waitForDone(callback) {
        function isDone(r) {
            return r.getBoolean("done");
        }
        function getId(r) {
            return r.id;
        }
        function checkAsyncResults(results) {
            var done = results.every(isDone);
            if (!done) {
                var ids = results.map(getId);
                sforce.metadata.checkStatus(ids, checkAsyncResults);
            } else {
                callback(results);
            }
        }
        return checkAsyncResults;
    }

#### create
    var component;
    component = new sforce.Metadata("HomePageComponent");
    component.fullName = "MyComponent";
    component.pageComponentType = "htmlArea";
    component.width = "narrow";
    component.body = "<b>MyHomePageComponent</b>";
    sforce.metadata.create([component]);
#### update
    var update, component;
    update = new sforce.UpdateMetadata();
    update.currentName = "MyComponent";
    update.metadata = component = new sforce.Metadata("HomePageComponent");
    component.fullName = "MyComponent";
    component.pageComponentType = "htmlArea";
    component.width = "narrow";
    component.body = "<b>Updated</b>";
    sforce.metadata.update([update]);
#### delete
    var component;
    component = new sforce.Metadata("HomePageComponent");
    component.fullName = "MyComponent";
    sforce.metadata.deleteMetadata([component]);


### Declarative (File-Based) Calls
You must prepare independently way to treat zip archive.
For example, [JSZip](http://stuartk.com/jszip/) or [zip.js](http://gildas-lormeau.github.com/zip.js/).

#### retrieve
    function waitForDone(callback) {
        function getResult(id) {
            sforce.metadata.checkRetrieveStatus(id, callback);
        }
        function check(results) {
            var done = results[0].getBoolean("done");
            if (!done) {
                sforce.metadata.checkStatus([results[0].id], check);
            } else {
                getResult(results[0].id);
            }
        }
        return function (result) {
            check([result]);
        };
    }
    var req, result;
    req = new sforce.RetrieveRequest();
    req.apiVersion = "28.0";
    req.singlePackage = false;
    req.unpackaged = {
        types: [{name: "ApexPage", members:["spec"]}]
    };
    sforce.metadata.retrieve(req, waitForDone(function (result) {
        //
        // unzip result.zipFile
        //
    }));
###### Unzip retrieve result with [JSZip](http://stuartk.com/jszip/)
    zip = new JSZip(result.zipFile, {base64:true});
    console.log(zip.file("unpackaged/pages/MyPage.page").asText());
###### Unzip retrieve result with [zip.js](http://gildas-lormeau.github.com/zip.js/)
    zip.useWebWorkers = false;


    function getEntries(data64URI, onend) {
        zip.createReader(new zip.Data64URIReader(data64URI), function (reader) {
            reader.getEntries(onend);
        });
    }
    getEntries("data:application/zip;base64," + result.zipFile, function (entries) {
        entries.forEach(function (entry) {
            console.log(entry);
            var writer = new zip.TextWriter();
            entry.getData(writer, function (text) {
                console.log(text);
            });
        });
    });

#### deploy
    function waitForDone(callback) {
        function getResult(id) {
            sforce.metadata.checkDeployStatus(id, callback);
        }
        function check(results) {
            var done = results[0].getBoolean("done");
            if (!done) {
                sforce.metadata.checkStatus([results[0].id], check);
            } else {
                getResult(results[0].id);
            }
        }
        return function (result) {
            check([result]);
        };
    }
    var req, meta, package, b64, zipArchive;
    body = "public class MyClass{}";
    meta = new sforce.MetaXml("ApexClass");
    meta.apiVersion = 26;
    meta.status = "Active";
    package = new sforce.Package();
    package.version = 26;
    package.types = [
        {name: "ApexClass", members: ["MyClass"]}
    ];
    req = new sforce.DeployRequest();
    //
    // set zip archive to req.zipFile and deploy
    //
###### Zip deploy request with [JSZip](http://stuartk.com/jszip/)
    var zip;
    zip = new JSZip();
    zip.file("src/package.xml", package.toXml());
    zip.file("src/classes/MyClass.cls", "public class MyClass{}");
    zip.file("src/classes/MyClass.cls-meta.xml", meta.toXml());
    req.zipFile = zip.generate({base64: true});
    sforce.metadata.deploy(req, waitForDone(function (result) {
        console.log(result);
    }));
###### Zip deploy request with [zip.js](http://gildas-lormeau.github.com/zip.js/)
    zip.useWebWorkers = false;


    var writer;
    function onCreateWriterEnd(w) {
        writer = w;
        writer.add("src/package.xml", new zip.TextReader(package.toXml()), onWritePackageXmlEnd);
    }
    function onWritePackageXmlEnd() {
        writer.add("src/classes/MyClass.cls", new zip.TextReader(body), onWriteClassBodyEnd);
    }
    function onWriteClassBodyEnd() {
        writer.add("src/classes/MyClass.cls-meta.xml", new zip.TextReader(meta.toXml()), onWriteMetaXmlEnd);
    }
    function onWriteMetaXmlEnd() {
        writer.close(onWriteEnd);
    }
    function onWriteEnd(data) {
        req.zipFile = data.substr("data:;base64,".length);
        sforce.metadata.deploy(req, waitForDone(function (result) {
            console.log(result);
        }));
    }
    zip.createWriter(new zip.Data64URIWriter(), onCreateWriterEnd);

---


### See also
[Metadata API Developer's Guide](http://www.salesforce.com/us/developer/docs/api_meta/index.htm)


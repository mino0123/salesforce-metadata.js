describe("sforce.metadata", function () {
    var TEST_NAME = "MetadataJSTest";

    function waitSync(results) {
        var done = results[0].getBoolean("done");
        while (!done) {
            results = sforce.metadata.checkStatus([results[0].id]);
            done = results[0].getBoolean("done");
        }
        return results;
    }
    function waitFileBaseSync(result, method) {
        results = waitSync([result]);
        return sforce.metadata[method](results[0].id);
    }

    describe("Metadata XML Serialize", function () {
        describe("getKeys", function () {
            var obj, keys;
            obj = {
                fn: function () {},
                str: "string",
                number: 1,
                boolean: false,
                nullValue: null,
                obj: {},
                arr: []
            };
            keys = sforce.Metadata.prototype.getKeys(obj);
            it("returns an array", function () {
                expect(keys).toEqual(jasmine.any(Array));
            });
            describe("return value", function () {
                it("contains string property", function () {
                    expect(keys.indexOf("str")).toBeGreaterThan(-1);
                });
                it("contains number property", function () {
                    expect(keys.indexOf("number")).toBeGreaterThan(-1);
                });
                it("contains boolean property", function () {
                    expect(keys.indexOf("boolean")).toBeGreaterThan(-1);
                });
                it("contains null property", function () {
                    expect(keys.indexOf("nullValue")).toBeGreaterThan(-1);
                });
                it("contains object property", function () {
                    expect(keys.indexOf("obj")).toBeGreaterThan(-1);
                });
                it("contains array property", function () {
                    expect(keys.indexOf("arr")).toBeGreaterThan(-1);
                });
                it("not contains function property", function () {
                    expect(keys.indexOf("fn")).toBe(-1);
                });
            });
        });

        describe("writeString", function () {
            var metadata, writer, result;
            writer = new sforce.XmlWriter();
            metadata = new sforce.Metadata("MetadataJSTest");
            metadata.writeString("name", "value", writer);
            result = writer.toString();
            it("write a string value", function () {
                expect(result).toBe("<name>value</name>");
            });
        });

        describe("writeArray", function () {
            var metadata, writer, result;
            writer = new sforce.XmlWriter();
            metadata = new sforce.Metadata("MetadataJSTest");
            metadata.writeArray("name", [1,2], writer);
            result = writer.toString();
            it("write a array value", function () {
                expect(result).toBe("<name>1</name><name>2</name>");
            });
        });

        describe("writeValue", function () {
            describe("value is null", function () {
                var metadata, writer, result;
                writer = new sforce.XmlWriter();
                metadata = new sforce.Metadata("MetadataJSTest");
                metadata.writeValue("name", null, writer);
                result = writer.toString();
                it("write xsi:nill attribute", function () {
                    expect(result).toBe('<name xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nill="true"/>');
                });
            });
        });
    });

    describe("package.xml Serialize", function () {
        var xml = sforce.Package.toXml({
            types: [{name: "ApexClass", members: ["Class1", "Class2"]}],
            version: 26
        });
        it("contains type name", function () {
            expect(xml).toContain("ApexClass");
        });
        it("contains member name 1", function () {
            expect(xml).toContain("Class1");
        });
        it("contains member name 2", function () {
            expect(xml).toContain("Class2");
        });
        it("contains version", function () {
            expect(xml).toContain("version");
            expect(xml).toContain("26");
        });
    });

    describe("Utility API", function () {
        describe("describeMetadata(26)", function () {
            var dr;
            beforeEach(function () {
                if (!dr) {
                    dr = sforce.metadata.describeMetadata(26);
                }
            });
            it("method returns a value", function () {
                expect(dr).not.toBeNull();
            });
            it("metadataObjects is an Array", function () {
                expect(dr.metadataObjects).toBeDefined();
                expect(dr.metadataObjects).toEqual(jasmine.any(Array));
            });
            it("has organizationNamespace", function () {
                expect(dr.organizationNamespace).toBeDefined();
            });
            it("has partialSaveAllowed", function () {
                expect(dr.partialSaveAllowed).toBeDefined();
            });
            it("has testRequired", function () {
                expect(dr.testRequired).toBeDefined();
            });
        });

        describe("listMetadata({queries: [{type: 'ApexPage'}, {type: 'Layout'}], asOfVersion: 26})", function () {
            var results;
            beforeEach(function () {
                if (!results) {
                    results = sforce.metadata.listMetadata(
                        {queries: [{type: 'ApexPage'}, {type: 'Layout'}], asOfVersion: 26}
                        );
                }
            });
            it("returns an array", function () {
                expect(results).toEqual(jasmine.any(Array));
            });
            it("contains ApexPage", function () {
                function isApexPage(m) {
                    return m.type === "ApexPage";
                }
                expect(results.filter(isApexPage).length).toBeGreaterThan(0);
            });
            it("contains Layout", function () {
                function isLayout(m) {
                    return m.type === "Layout";
                }
                expect(results.filter(isLayout).length).toBeGreaterThan(0);
            });
        });
    });

    describe("CRUD-Based API", function () {
        function tryCreate(metadata) {
            var results;
            results = sforce.metadata.create([metadata]);
            results = waitSync(results);
            if (results[0].state !== "Completed") {
                console.log(results[0]);
                throw results[0];
            }
            expect(results[0].state).toBe("Completed");
            return results;
        }
        function tryUpdate(currentName, metadata) {
            var updateData, results;
            updateData = new sforce.UpdateMetadata();
            updateData.currentName = currentName;
            updateData.metadata = metadata;
            results = sforce.metadata.update([updateData]);
            results = waitSync(results);
            if (results[0].state !== "Completed") {
                console.log(results[0]);
                throw results[0];
            }
            expect(results[0].state).toBe("Completed");
            return results;
        }
        function tryDelete(metadata) {
            var results;
            results = sforce.metadata.deleteMetadata([metadata]);
            results = waitSync(results);
            if (results[0].state !== "Completed") {
                console.log(results[0]);
                throw results[0];
            }
            expect(results[0].state).toBe("Completed");
            return results;
        }
        
        // dependent report and object
        xdescribe("AnalyticSnapshot", function () {
            var m, result;
            m = new sforce.Metadata("AnalyticSnapshot");
        });

        xdescribe("ArticleType Layout", function () {
            var name, m, results;
            name = "MetadataJSTest";
            m = new sforce.Metadata("ArticleType");
            m.fullName = name;
            m.deploymentStatus = "InDevelopment";

            it("is createable", function () {
                var results;
                results = sforce.metadata.create([m]);
                results = waitSync(results);
                expect(results[0].state).toBe("Completed");
            });
        });

        describe("ApexPage", function () {
            var page, query;
            query = "SELECT Markup FROM ApexPage WHERE Name = '" + TEST_NAME + "'";
            page = new sforce.Metadata("ApexPage");
            page.fullName = TEST_NAME;
            page.label = TEST_NAME;
            page.apiVersion = 26;
            page.content = new sforce.Base64Binary("<apex:page></apex:page>");

            it("is creatable", function () {
                var qr;
                tryCreate(page);
                qr = sforce.connection.query(query);
                expect(qr.getInt("size")).toBe(1);
            });
            
            it("is updateable", function () {
                var markup, qr;
                markup = "<apex:page >updated</apex:page>";
                page.content = new sforce.Base64Binary(markup);
                tryUpdate(TEST_NAME, page);
                qr = sforce.connection.query(query);
                expect(qr.getInt("size")).toBe(1);
                expect(qr.getArray("records")[0].Markup).toBe(markup);
            });

            it("is deleteable", function () {
                var qr;
                tryDelete(page);
                qr = sforce.connection.query(query);
                expect(qr.getInt("size")).toBe(0);
            });
        });

        describe("ApexComponent", function () {
            var query, component;
            query = "SELECT Markup FROM ApexComponent WHERE Name = '" + TEST_NAME + "'";
            component = new sforce.Metadata("ApexComponent");
            component.fullName = TEST_NAME;
            component.label = TEST_NAME;
            component.apiVersion = 26;
            component.content = new sforce.Base64Binary("<apex:component ></apex:component>");
            it("is creatable", function () {
                var qr;
                tryCreate(component);
                qr = sforce.connection.query(query);
                expect(qr.getInt("size")).toBe(1);
            });
            it("is updateable", function () {
                var qr;
                markup = "<apex:component >updated</apex:component>";
                component.content = new sforce.Base64Binary(markup);
                tryUpdate(TEST_NAME, component);
                qr = sforce.connection.query(query);
                expect(qr.getInt("size")).toBe(1);
                expect(qr.getArray("records")[0].Markup).toBe(markup);
            });
            it("is deleteable", function () {
                var qr;
                tryDelete(component);
                qr = sforce.connection.query(query);
                expect(qr.getInt("size")).toBe(0);
            });
        });

        describe("CustomApplication", function () {
            var application;
            application = new sforce.Metadata("CustomApplication");
            application.fullName = TEST_NAME;
            application.label = TEST_NAME;
            it("is createable", function () {
                tryCreate(application);
            });
            // duplicate value found: <unknown>の値が重複しているレコードの ID: <unknown>
            xit("is updateable", function () {
                tryUpdate(TEST_NAME, application);
            });
            it("is deleteable", function () {
                tryDelete(application);
            });
        });

        describe("CustomApplicationComponent", function () {
            var appComp;
            appComp = new sforce.Metadata("CustomApplicationComponent");
            appComp.fullName = TEST_NAME;
            appComp.buttonText = TEST_NAME;
            appComp.isHeightFixed = true;
            appComp.isHidden = true;
            appComp.isWidthFixed = true;
            appComp.visualforcePage = "spec";
            it("is createable", function () {
                tryCreate(appComp);
            });
            //duplicate value found: <unknown>の値が重複しているレコードの ID: <unknown>
            xit("is updateable", function () {
                tryUpdate(TEST_NAME, appComp);
            });
            it("is deleteable", function () {
                tryDelete(appComp);
            });
        });

        // {faultcode:'sf:UNKNOWN_EXCEPTION', faultstring:'null: メタデータの作成/更新から子を作成できません。「MetadataJSTest」という名前の CustomLabel を別途作成してください。', }
        xdescribe("CustomLabels", function () {
            var labels;
            labels = new sforce.Metadata("CustomLabels");
            labels.labels = [
                {
                    fullName: TEST_NAME,
                    // categories: null,
                    language: "ja",
                    "protected": false,
                    shortDescription: "",
                    value: name
                }
            ];
            it("is createable", function () {
                tryCreate(labels);
            });
            it("is updateable", function () {
                tryUpdate(TEST_NAME, labels);
            });
            it("is deleteable", function () {
                tryDelete(labels);
            });
        });

        describe("CustomLabel", function () {
            var label;
            label = new sforce.Metadata("CustomLabel");
            label.fullName = TEST_NAME;
            label.categories = null;
            label.language = "ja";
            label["protected"] = false;
            label.shortDescription = TEST_NAME;
            label.value = TEST_NAME;
            it("is createable", function () {
                tryCreate(label);
            });
            it("is updateable", function () {
                tryUpdate(TEST_NAME, label);
            });
            it("is deleteable", function () {
                tryDelete(label);
            });
        });

        // can not hard delete
        xdescribe("CustomObject", function () {
            var o, f, objName, results;
            objName = "TestCustomObject__c";
            o = new sforce.Metadata("CustomObject");
            o.fullName = objName;
            o.label = objName;
            o.deploymentStatus = "Deployed";
            o.sharingModel = "ReadWrite";
            f = new sforce.Metadata("CustomField");
            f.fullName = [objName, "Name"].join(".");
            f.type = "AutoNumber";
            f.formula = "0";
            f.label = "Name";
            f.startingNumber = 1;
            o.nameField = f;
            it("is creatable", function () {
                tryCreate(o);
            });
            it("is updateable", function () {
                tryUpdate(objName, o);
            });
            it("deleteable (Deploy)", function () {
                var req, pack, destructiveChanges;
                pack = sforce.Package.toXml({
                    types: [], version: 26
                });
                destructiveChanges = sforce.Package.toXml({
                    types: [{members:[objName], name:"CustomObject"}],
                    version: 26
                });
                files = [
                    {name: "src", dir:[
                        {name: "package.xml", buffer: pack},
                        {name:"destructiveChanges.xml", buffer:destructiveChanges}
                    ]}
                ];
                buffer = jz.zip.pack({
                    files: files,
                    level: 0
                });
                arr = new Uint8Array(buffer);
                text = Array.prototype.map.call(arr, function (n) {
                    return String.fromCharCode(n);
                }).join("");
                b64 = new sforce.Base64Binary(text);
                req = new sforce.DeployRequest();
                req.deployOptions = {};
                req.zipFile = b64.toString();
                result = sforce.metadata.deploy(req);
                result = waitFileBaseSync(result, "checkDeployStatus");
                expect(result.getBoolean("success")).toBe(true);
            });
        });

        // この ドキュメントの一意の名前 はすでに存在しているか、以前に使用されていました。別の名前を選択してください。
        xdescribe("Document", function () {
            var fullName, doc, body, folderName, folder;
            folderName = TEST_NAME + "DocumentFolder";
            fullName = folderName + "/" + TEST_NAME + "2";
            body = new sforce.Base64Binary("content");
            doc = new sforce.Metadata("Document");
            doc.fullName = fullName;
            doc.name = fullName;
            doc.content = body.toString();
            doc["public"] = false;
            doc.internalUseOnly = true;
            folder = new sforce.Metadata("DocumentFolder");
            folder.fullName = folderName;
            folder.name = folderName;
            folder.accessType = "Public";
            describe("Folder", function () {
                it("is createable", function () {
                    tryCreate(folder);
                });
            });
            // この ドキュメントの一意の名前 はすでに存在しているか、以前に使用されていました。別の名前を選択してください。
            it("is createable", function () {
                tryCreate(doc);
            });
            it("is updateable", function () {
                tryUpdate(fullName, doc);
            });
            it("is deleteable", function () {
                tryDelete(doc);
            });
            describe("Folder", function () {
                it("is updateable", function () {
                    tryUpdate(folderName, folder);
                });
                it("is deleteable", function () {
                    tryDelete(folder);
                });
            });
        });

        describe("EmailTemplate", function () {
            var tmpl, folder;
            tmpl = new sforce.Metadata("EmailTemplate");
            tmpl.fullName = TEST_NAME + "/" + TEST_NAME;
            tmpl.available = false;
            tmpl.encodingKey = "UTF-8";
            tmpl.name = TEST_NAME;
            tmpl.style = "none";
            tmpl.type = "text";
            folder = new sforce.Metadata("EmailFolder");
            folder.fullName = TEST_NAME;
            folder.name = TEST_NAME;
            folder.accessType = "Public";
            describe("Folder", function () {
                it("is createable", function () {
                    tryCreate(folder);
                });
            });
            it("is createable", function () {
                tryCreate(tmpl);
            });
            it("is updateable", function () {
                tryUpdate(tmpl.fullName, tmpl);
            });
            it("is deleteable", function () {
                tryDelete(tmpl);
            });
            describe("Folder", function () {
                it("is updateable", function () {
                    tryUpdate(TEST_NAME, folder);
                });
                it("is deleteable", function () {
                    tryDelete(folder);
                });
            });
        });

        // This type of object is not available for this organization
        xdescribe("EntitlementTemplate", function () {
            var ent;
            ent = new sforce.Metadata("EntitlementTemplate");
            ent.fullName = TEST_NAME;
            it("is createable", function () {
                tryCreate(ent);
            });
            it("is updateable", function () {
                tryUpdate(TEST_NAME, ent);
            });
            it("is deleteable", function () {
                tryDelete(ent);
            });
        });

        describe("Folder", function () {
            function folderTest(type) {
                describe(type, function () {
                    var folder;
                    folder = new sforce.Metadata(type);
                    folder.fullName = TEST_NAME;
                    folder.name = TEST_NAME;
                    folder.accessType = "Hidden";
                    it("is createable", function () {
                        tryCreate(folder);
                    });
                    it("is updateable", function () {
                        tryUpdate(TEST_NAME, folder);
                    });
                    it("is deleteable", function () {
                        tryDelete(folder);
                    });
                });
            }
            folderTest("DocumentFolder");
            folderTest("ReportFolder");
            folderTest("DashboardFolder");
        });

        describe("Flow", function () {
            var flow;
            flow = new sforce.Metadata("Flow");
            flow.fullName = TEST_NAME + "-1";
            flow.label = flow.fullName;
            flow.screens = [
                {name: TEST_NAME, label: TEST_NAME, locationX: 0, locationY: 0, fields: []}
            ];
            flow.startElementReference = TEST_NAME;
            it("is createable", function () {
                tryCreate(flow);
            });
            it("is updateable", function () {
                tryUpdate(flow.fullName, flow);
            });
            it("is deleteable", function () {
                tryDelete(flow);
            });
        });

        describe("Group", function () {
            var group;
            group = new sforce.Metadata("Group");
            group.fullName = TEST_NAME;
            group.name = TEST_NAME;
            it("is createable", function () {
                tryCreate(group);
            });
            it("is updateable", function () {
                tryUpdate(group.fullName, group);
            });
            it("is deleteable", function () {
                tryDelete(group);
            });
        });

        describe("HomePageComponent", function () {
            var homeComp;
            homeComp = new sforce.Metadata("HomePageComponent");
            homeComp.fullName = TEST_NAME;
            homeComp.pageComponentType = "htmlArea";
            homeComp.width = "narrow";
            homeComp.body = TEST_NAME;
            it("is createable", function () {
                tryCreate(homeComp);
            });
            it("is updateable", function () {
                tryUpdate(homeComp.fullName, homeComp);
            });
            it("is deleteable", function () {
                tryDelete(homeComp);
            });
        });

        describe("HomePageLayout", function () {
            var homeLayout;
            homeLayout = new sforce.Metadata("HomePageLayout");
            homeLayout.fullName = TEST_NAME;
            it("is createable", function () {
                tryCreate(homeLayout);
            });
            it("is updateable", function () {
                tryUpdate(homeLayout.fullName, homeLayout);
            });
            it("is deleteable", function () {
                tryDelete(homeLayout);
            });
        });

        describe("Layout", function () {
            var layout;
            layout = new sforce.Metadata("Layout");
            layout.fullName = "Account-" + TEST_NAME;
            layout.layoutSections = [{
                layoutColumns: [{layoutItems: [
                    {field: "Name", behavior: "Required"},
                    {field: "ParentId", behavior: "Required"}
                ]}],
                style: "OneColumn"
            }];
            it("is createable", function () {
                tryCreate(layout);
            });
            it("is updateable", function () {
                tryUpdate(layout.fullName, layout);
            });
            it("is deleteable", function () {
                tryDelete(layout);
            });
        });

        describe("Letterhead", function () {
            var letterhead;
            letterhead = new sforce.Metadata("Letterhead");
            letterhead.fullName = TEST_NAME;
            letterhead.available = false;
            letterhead.backgroundColor = "#000000";
            letterhead.bodyColor = "#000000";
            letterhead.bottomLine = {color: "#000000", height: 10};
            letterhead.footer = {backgroundColor: "#000000", height: 10};
            letterhead.header = {backgroundColor: "#000000", height: 10};
            letterhead.middleLine = {color: "#000000", height: 10};
            letterhead.name = TEST_NAME;
            letterhead.topLine = {color: "#000000", height: 10};
            it("is createable", function () {
                tryCreate(letterhead);
            });
            it("is updateable", function () {
                tryUpdate(letterhead.fullName, letterhead);
            });
            it("is deleteable", function () {
                tryDelete(letterhead);
            });
        });

        // INVALID_TYPE: This type of object is not available for this organization
        xdescribe("Portal", function () {
            var portal;
            portal = new sforce.Metadata("Portal");
            portal.fullName = TEST_NAME;
            portal.active = false;
            portal.emailSenderAddress = "metadatajstest@example.com";
            portal.emailSenderName = TEST_NAME;
            portal.type = "Partner";
            it("is createable", function () {
                tryCreate(portal);
            });
            it("is updateable", function () {
                tryUpdate(portal.fullName, portal);
            });
            it("is deleteable", function () {
                tryDelete(portal);
            });
        });

        describe("Profile", function () {
            var profile;
            profile = new sforce.Metadata("Profile");
            profile.fullName = TEST_NAME;
            it("is createable", function () {
                tryCreate(profile);
            });
            it("is updateable", function () {
                tryUpdate(profile.fullName, profile);
            });
            it("is deleteable", function () {
                tryDelete(profile);
            });
        });

        describe("Queue", function () {
            var query, queue;
            query = "SELECT count() FROM Group WHERE Type='Queue' AND DeveloperName = '" + TEST_NAME + "'";
            queue = new sforce.Metadata("Queue");
            queue.name = TEST_NAME;
            queue.fullName = TEST_NAME;
            queue.queueSobject = {
                sobjectType: "Lead"
            };
            it("is createable", function () {
                var qr;
                tryCreate(queue);
                qr = sforce.connection.query(query);
                expect(qr.getInt("size")).toBe(1);
            });
            it("is updateable", function () {
                var qr;
                tryUpdate(TEST_NAME, queue);
                qr = sforce.connection.query(query);
                expect(qr.getInt("size")).toBe(1);
            });
            it("is deleteable", function () {
                var qr;
                tryDelete(queue);
                qr = sforce.connection.query(query);
                expect(qr.getInt("size")).toBe(0);
            });
        });

        describe("RemoteSiteSetting", function () {
            var remotesite;
            remotesite = new sforce.Metadata("RemoteSiteSetting");
            remotesite.fullName = TEST_NAME;
            remotesite.disableProtocolSecurity = false;
            remotesite.isActive = false;
            remotesite.url = "http://example.com";
            it("is createable", function () {
                tryCreate(remotesite);
            });
            it("is updateable", function () {
                tryUpdate(remotesite.fullName, remotesite);
            });
            it("is deleteable", function () {
                tryDelete(remotesite);
            });
        });

        // Cannot find folder:MetadataJSTest
        xdescribe("Report", function () {
            var report;
            report = new sforce.Metadata("Report");
            report.fullName = TEST_NAME;
            report.name = "Account";
            report.format = "Tabular";
            report.reportType = "Account";
            it("is createable", function () {
                tryCreate(report);
            });
            it("is updateable", function () {
                tryUpdate(TEST_NAME, report);
            });
            it("is deleteable", function () {
                tryDelete(report);
            });
        });

        describe("ReportType", function () {
            var type;
            type = new sforce.Metadata("ReportType");
            type.fullName = TEST_NAME;
            type.baseObject = "Account";
            type.category = "accounts";
            type.deployed = false;
            type.label = TEST_NAME;
            type.sections = [{masterLabel: "masterLabel"}];
            it("is createable", function () {
                tryCreate(type);
            });
            it("is updateable", function () {
                tryUpdate(TEST_NAME, type);
            });
            it("is deleteable", function () {
                tryDelete(type);
            });
        });

        describe("Role", function () {
            var role;
            role = new sforce.Metadata("Role");
            role.fullName = TEST_NAME;
            role.name = TEST_NAME;
            it("is createable", function () {
                tryCreate(role);
            });
            it("is updateable", function () {
                tryUpdate(role.fullName, role);
            });
            it("is deleteable", function () {
                tryDelete(role);
            });
        });

        describe("StaticResource", function () {
            var query, resource;
            query = "SELECT Body FROM StaticResource WHERE Name = '" + TEST_NAME + "'";
            resource = new sforce.Metadata("StaticResource");
            resource.fullName = TEST_NAME;
            resource.cacheControl = "Public";
            resource.contentType = "text/plain";
            resource.content = new sforce.Base64Binary("TestStaticResource");
            it("is createable", function () {
                var qr;
                tryCreate(resource);
                qr = sforce.connection.query(query);
                expect(qr.getInt("size")).toBe(1);
            });
            it("is updateable", function () {
                var qr;
                content = "updated";
                resource.content = new sforce.Base64Binary(content);
                tryUpdate(TEST_NAME, resource);
                qr = sforce.connection.query(query);
                expect(qr.getInt("size")).toBe(1);
                body = new sforce.Base64Binary().decode(qr.getArray("records")[0].Body);
                expect(body).toBe(content);
            });
            it("is deleteable", function () {
                var qr;
                tryDelete(resource);
                qr = sforce.connection.query(query);
                expect(qr.getInt("size")).toBe(0);
            });
        });

        // INVALID_TYPE: This type of object is not available for this organization
        xdescribe("Territory", function () {
            var territory;
            territory = new sforce.Metadata("Territory");
            territory.fullName = TEST_NAME;
            territory.name = TEST_NAME;
            it("is createable", function () {
                tryCreate(territory);
            });
            it("is updateable", function () {
                tryUpdate(territory.fullName, territory);
            });
            it("is deleteable", function () {
                tryDelete(territory);
            });
        });

        // INVALID_TYPE: This type of object is not available for this organization
        xdescribe("Translations", function () {
            var translations;
            translations = new sforce.Metadata("Translations");
            translations.fullName = "ja";
            it("is createable", function () {
                tryCreate(translations);
            });
            it("is updateable", function () {
                tryUpdate(translations.fullName, translations);
            });
            xit("is deleteable", function () {
                // delete all transrations in organizaiton.
            });
        });

        // Cannot create workflow directly; must create the CustomObject first
        xdescribe("Workflow", function () {
            var workflow;
            workflow = new sforce.Metadata("Workflow");
            workflow.fullName = "Account." + TEST_NAME;
            it("is createable", function () {
                tryCreate(workflow);
            });
            it("is updateable", function () {
                tryUpdate(workflow.fullName, workflow);
            });
            it("is deleteable", function () {
                tryDelete(workflow);
            });
        });
    });

    describe("Declarative (File-Based) API", function () {
        describe("retrieve", function () {
            var req, result;
            req = new sforce.RetrieveRequest();
            req.apiVersion = "26.0";
            req.singlePackage = false;
            req.unpackaged = {
                types: [{name: "ApexPage", members:["spec"]}]
            };
            result = sforce.metadata.retrieve(req);
            it("success", function () {
                var b64, decoded, zip, content;
                result = waitFileBaseSync(result, "checkRetrieveStatus");
                zip = new JSZip(result.zipFile, {base64:true});
                content = zip.file("unpackaged/pages/spec.page").data;
                expect(content).not.toBe(null);
            });
        });
        describe("deploy", function () {
            var req, meta, pack, result;
            req = new sforce.DeployRequest();
            req.deployOptions = {
                allowMissingFiles: true,
                autoUpdatePackage: false,
                checkOnly        : false,
                ignoreWarnings   : true,
                performRetrieve  : false,
                purgeOnDelete    : true,
                rollbackOnError  : true,
                runAllTests      : false,
                runTests         : [],
                singlePackage    : true
            };
            pack = new sforce.Package();
            pack.version = 26;
            pack.types = [
                {name: "ApexClass", members: ["MetadataJSTest"]}
            ];
            meta = new sforce.MetaXml("ApexClass");
            meta.apiVersion = 26;
            meta.status = "Active";
            zip = new JSZip();
            zip.file("src/package.xml", pack.toXml());
            zip.file("src/classes/MetadataJSTest.cls", "public class MetadataJSTest{}");
            zip.file("src/classes/MetadataJSTest.cls-meta.xml", meta.toXml());
            req.zipFile = zip.generate({base64: true});
            it("success", function () {
                result = sforce.metadata.deploy(req);
                result = waitFileBaseSync(result, "checkDeployStatus");
                expect(result.getBoolean("success")).toBe(true);
            });
        });
        describe("deploy (destructiveChanges)", function () {
            var req, pack;
            req = new sforce.DeployRequest();
            pack = new sforce.Package();
            pack.version = 26;
            zip = new JSZip();
            zip.file("src/package.xml", pack.toXml());
            pack.types = [{name: "ApexClass", members: ["MetadataJSTest"]}];
            zip.file("src/destructiveChanges.xml", pack.toXml());
            req.zipFile = zip.generate({base64: true});
            it("success", function () {
                result = sforce.metadata.deploy(req);
                result = waitFileBaseSync(result, "checkDeployStatus");
                expect(result.getBoolean("success")).toBe(true);
            });
        });
    });
});
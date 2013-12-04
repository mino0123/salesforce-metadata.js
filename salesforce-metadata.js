/*
salesforce-metadata.js v0.1.0
Copyright (c) 2012 Yuta Minowa
Licensed under the MIT license
https://github.com/mino0123/salesforce-metadata.js/LICENSE
*/
/*jslint nomen: true */
/*global sforce */
(function () {
    "use strict";

    if (typeof sforce === "undefined" || !sforce.Connection) {
        throw new Error("connection.js not loaded.");
    }

    sforce.MetadataConnection = function () {};

    sforce.MetadataConnection.prototype = new sforce.Connection();

    sforce.MetadataConnection.prototype.metadataNs = "http://soap.sforce.com/2006/04/metadata";
    sforce.MetadataConnection.prototype.metadataNsPrefix = "m";
    sforce.MetadataConnection.prototype.xsiNs = "http://www.w3.org/2001/XMLSchema-instance";

    sforce.MetadataConnection.prototype.create = function (metadataArray, callback) {
        var arg = new sforce.internal.Parameter("metadata", metadataArray, true);
        return this._invoke("create", [arg], true, callback);
    };

    sforce.MetadataConnection.prototype.update = function (metadataArray, callback) {
        var arg = new sforce.internal.Parameter("updateMetadata", metadataArray, true);
        return this._invoke("update", [arg], true, callback);
    };

    sforce.MetadataConnection.prototype.deleteMetadata = function (metadataArray, callback) {
        var arg = new sforce.internal.Parameter("metadata", metadataArray, true);
        return this._invoke("delete", [arg], true, callback);
    };

    sforce.MetadataConnection.prototype.checkStatus = function (asyncIds, callback) {
        var arg = new sforce.internal.Parameter("asyncProcessId", asyncIds, true);
        return this._invoke("checkStatus", [arg], true, callback);
    };

    sforce.MetadataConnection.prototype.describeMetadata = function (version, callback) {
        var arg = new sforce.internal.Parameter("asOfVersion", version, false);
        return this._invoke("describeMetadata", [arg], false, callback);
    };

    sforce.MetadataConnection.prototype.listMetadata = function (request, callback) {
        var args, queries, asOfVersion;
        args = [];
        queries = request.queries.map(function (q) {
            var xml = new sforce.Xml();
            xml._xsiType = "queries";
            xml.type = q.type;
            xml.folder = q.folder;
            return xml;
        });
        args.push(new sforce.internal.Parameter("queries", queries, true));
        asOfVersion = request.asOfVersion;
        if (typeof asOfVersion === "number") {
            args.push(new sforce.internal.Parameter("asOfVersion", asOfVersion, false));
        }
        return this._invoke("listMetadata", args, true, callback);
    };

    sforce.MetadataConnection.prototype.retrieve = function (req, callback) {
        var arg = new sforce.internal.Parameter("retrieveRequest", req, false);
        return this._invoke("retrieve", [arg], false, callback);
    };

    sforce.MetadataConnection.prototype.checkRetrieveStatus = function (asyncId, callback) {
        var arg = new sforce.internal.Parameter("asyncProcessId", asyncId, false);
        return this._invoke("checkRetrieveStatus", [arg], false, callback);
    };

    sforce.MetadataConnection.prototype.deploy = function (req, callback) {
        var args = [];
        args.push(new sforce.internal.Parameter("zipFile", req.zipFile, false));
        if (req.deployOptions) {
            args.push(new sforce.internal.Parameter("deployOptions", req.deployOptions, false));
        }
        return this._invoke("deploy", args, false, callback);
    };

    sforce.MetadataConnection.prototype.checkDeployStatus = function (asyncId, callback) {
        var args = [];
        args.push(new sforce.internal.Parameter("asyncProcessId", asyncId, false));
        args.push(new sforce.internal.Parameter("includeDetails", true, false));
        return this._invoke("checkDeployStatus", args, false, callback);
    };

    sforce.MetadataConnection.prototype.startEnvelope = function (w) {
        w.startEnvelope();
        w.writeNamespace(this.xsiNs, "xsi");
        w.writeNamespace(this.metadataNs, this.metadataNsPrefix);
        w.writeNamespace(this.sforceNs, "p");
    };

    sforce.MetadataConnection.prototype.writeHeader = function (w, ns) {
        var soapNS = sforce.XmlWriter.prototype.soapNS;
        w.writeStartElement("Header", soapNS);
        w.writeStartElement("SessionHeader", this.metadataNs);
        w.writeStartElement("sessionId", this.sforceNs);
        w.writeText(this.sessionId);
        w.writeEndElement("sessionId", this.sforceNs);
        w.writeEndElement("SessionHeader", this.metadataNs);
        w.writeEndElement("Header", soapNS);
    };

    sforce.MetadataConnection.prototype._invoke = function (method, args, isArray, callback) {
        this.validateCallback(callback);

        var writer = new sforce.XmlWriter(),
            transport;
        this.startEnvelope(writer);
        this.writeHeader(writer, this.metadataNs);

        writer.startBody();
        writer.writeStartElement(method, this.metadataNs);

        this.validateArgs(args);
        this.writeArguments(writer, args, this.metadataNs);

        writer.writeEndElement(method, this.metadataNs);
        writer.endBody();
        writer.endEnvelope();

        transport = new sforce.SoapTransport();
        return transport.send(this.serverUrl, writer, isArray, callback);
    };

    sforce.MetadataConnection.prototype.validateCallback = function (callback) {
        if (callback) {
            if (typeof callback !== "function") {
                if (!callback.onSuccess) {
                    throw new Error("onSuccess not defined in the callback");
                }
                if (!callback.onFailure) {
                    throw new Error("onFailure not defined in the callback");
                }
            }
        }
    };

    sforce.MetadataConnection.prototype.validateArgs = function (args) {
        var i,
            len = args.length,
            arg,
            isArray,
            name,
            value,
            valueIsArray;
        for (i = 0; i < len; i += 1) {
            arg = args[i];
            isArray = arg.isArray;
            name = arg.name;
            value = arg.value;
            valueIsArray = Array.isArray(value);
            if (value !== null) {
                if (isArray && !valueIsArray) {
                    throw new Error("arg " + i + " '" + name + "' is an array. But passed in value is not an array");
                }
                if (!isArray && valueIsArray) {
                    throw new Error("arg " + i + " '" + name + "' is not an array. But passed in value is an array");
                }
            }
        }
    };

    sforce.MetadataConnection.prototype.writeArguments = function (writer, args, namespace) {
        var i, len, arg, name, value;
        len = args.length;
        for (i = 0; i < len; i += 1) {
            arg = args[i];
            name = arg.name;
            value = arg.value;
            if (value === null) {
                this.writeOne(writer, name, null, namespace);
            } else if (Array.isArray(value)) {
                this.writeArrayArgument(writer, name, value, namespace);
            } else {
                this.writeOne(writer, name, value, namespace);
            }
        }
    };

    sforce.MetadataConnection.prototype.writeArrayArgument = function (writer, name, arr, namespace) {
        var i, len, obj;
        len = arr.length;
        for (i = 0; i < len; i += 1) {
            obj = arr[i];
            if (!obj) {
                throw new Error("Array element at " + i + " is null.");
            }
            this.writeOne(writer, name, obj, namespace);
        }
    };


    sforce.Metadata = function (type) {
        this._xsiType = type;
    };

    sforce.Metadata.prototype = new sforce.Xml();

    sforce.Metadata.prototype.toXml = function (sobjectNs, name, writer) {
        writer.writeStartElement(name, sobjectNs);
        if (this._xsiType) {
            writer.writeXsiType(sforce.MetadataConnection.prototype.metadataNsPrefix + ":" + this._xsiType);
        }
        this.writeObject(null, this, writer);
        writer.writeEndElement(name, sobjectNs);
    };

    sforce.Metadata.prototype.writeValue = function (name, obj, writer) {
        if (obj === null) {
            writer.writeNameValueNode(name, null);
        } else if (obj instanceof sforce.Base64Binary) {
            this.writeString(name, obj.toString(), writer);
        } else if (Array.isArray(obj)) {
            this.writeArray(name, obj, writer);
        } else if (typeof obj === "object") {
            this.writeObject(name, obj, writer);
        } else {
            this.writeString(name, obj, writer);
        }
    };

    sforce.Metadata.prototype.writeObject = function (name, obj, writer) {
        var keys, len, i, k, v;
        keys = this.getKeys(obj);
        len = keys.length;
        if (name) {
            writer.writeStartElement(name);
        }
        for (i = 0; i < len; i += 1) {
            k = keys[i];
            v = obj[k];
            this.writeValue(k, v, writer);
        }
        if (name) {
            writer.writeEndElement(name);
        }
    };

    sforce.Metadata.prototype.writeArray = function (name, arr, writer) {
        var len, i;
        len = arr.length;
        for (i = 0; i < len; i += 1) {
            this.writeValue(name, arr[i], writer);
        }
    };

    sforce.Metadata.prototype.writeString = function (name, value, writer) {
        writer.writeStartElement(name);
        writer.writeText(value);
        writer.writeEndElement(name);
    };

    sforce.Metadata.prototype.getKeys = function (obj) {
        function isNotMetaProperty(name) {
            return name.indexOf("_") !== 0;
        }
        function isNotFunction(name) {
            return typeof obj[name] !== "function";
        }
        var keys = Object.keys(obj);
        return keys.filter(isNotMetaProperty).filter(isNotFunction);
    };


    sforce.UpdateMetadata = function (metadata) {
        this.metadata = metadata;
    };
    sforce.UpdateMetadata.prototype = new sforce.Xml();
    sforce.UpdateMetadata.prototype._xsiType = "UpdateMetadata";

    sforce.RetrieveRequest = function () {};
    sforce.RetrieveRequest.prototype = new sforce.Metadata("RetrieveRequest");

    sforce.DeployRequest = function () {};
    sforce.DeployRequest.prototype = new sforce.Metadata("DeployRequest");


    sforce.Package = function (opt_obj) {
        opt_obj = opt_obj || {};
        this.types = opt_obj.types || [];
        this.version = opt_obj.version || null;
    };
    sforce.Package.prototype = new sforce.Metadata();
    sforce.Package.prototype._toXml = sforce.Package.prototype.toXml;
    sforce.Package.prototype.toXml = function () {
        var w;
        w = new sforce.XmlWriter();
        this._toXml(null, "Package", w);
        return w.toString();
    };
    sforce.Package.toXml = function (obj) {
        return new sforce.Package(obj).toXml();
    };

    sforce.MetaXml = function (_metadataType) {
        this._metadataType = _metadataType;
    };
    sforce.MetaXml.prototype = new sforce.Metadata();
    sforce.MetaXml.prototype._toXml = sforce.MetaXml.prototype.toXml;
    sforce.MetaXml.prototype.toXml = function () {
        var w;
        w = new sforce.XmlWriter();
        this._toXml(null, this._metadataType, w);
        return w.toString();
    };
    sforce.MetaXml.getKeys = sforce.MetaXml.prototype.getKeys;
    sforce.MetaXml.toXml = function (obj) {
        var m, keys, i, len, k;
        m = new sforce.MetaXml(obj._metadataType);
        keys = this.getKeys(obj);
        len = keys.length;
        for (i = 0; i < len; i += 1) {
            k = keys[i];
            m[k] = obj[k];
        }
        return m.toXml();
    };


    sforce.metadata = new sforce.MetadataConnection();
    sforce.metadata.serverUrl = "/services/Soap/m/29.0";
    sforce.metadata.sessionId = sforce.connection.sessionId;


}());
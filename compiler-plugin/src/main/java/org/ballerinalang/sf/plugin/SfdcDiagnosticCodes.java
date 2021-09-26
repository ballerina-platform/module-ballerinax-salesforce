/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
 */

package org.ballerinalang.sf.plugin;

import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import static io.ballerina.tools.diagnostics.DiagnosticSeverity.ERROR;

/**
 * {@code SfdcDiagnosticCodes} is used to hold diagnostic codes.
 */
public enum SfdcDiagnosticCodes {
    SFDC_101("SFDC_101", "invalid annotation type '%s'", ERROR),
    SFDC_102("SFDC_102", "invalid method name '%s': expected one of the following types: "
            + "'onCreate', 'onUpdate', 'onDelete', 'onRestore'", ERROR),
    SFDC_103("SFDC_103", "%s parameter list", ERROR),
    SFDC_104("SFDC_104", "%s parameters in the parameter list", ERROR),
    SFDC_105("SFDC_105", "invalid parameter type '%s'", ERROR),
    SFDC_106("SFDC_106", "qualifier name required: '%s'", ERROR),
    SFDC_107("SFDC_107", "resource functions are not allowed in sfdc:Service", ERROR);

    private final String code;
    private final String message;
    private final DiagnosticSeverity severity;

    SfdcDiagnosticCodes(String code, String message, DiagnosticSeverity severity) {
        this.code = code;
        this.message = message;
        this.severity = severity;
    }

    public String getCode() {
        return code;
    }

    public String getMessage() {
        return message;
    }

    public DiagnosticSeverity getSeverity() {
        return severity;
    }
}

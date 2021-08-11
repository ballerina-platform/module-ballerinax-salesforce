/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.projects.DiagnosticResult;
import io.ballerina.projects.PackageCompilation;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Assertions;

import io.ballerina.projects.Package;

import java.nio.file.Path;
import java.nio.file.Paths;

public class CompilerPluginUnitTest {

    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources").toAbsolutePath();
    private static final Path DISTRIBUTION_PATH = Paths.get("build", "copy", "target", "ballerina-distribution").toAbsolutePath();
            //Paths.get().toAbsolutePath();

    private static final String SFDC_101 = "SFDC_101";
    private static final String SFDC_102 = "SFDC_102";
    private static final String SFDC_103 = "SFDC_103";
    private static final String SFDC_104 = "SFDC_104";
    private static final String SFDC_105 = "SFDC_105";
    private static final String SFDC_106 = "SFDC_106";
    private static final String SFDC_107 = "SFDC_107";
    private static final String BCE_1 = "BCE2631";
    private static final String BCE_2 = "BCE0517";

    private Package loadPackage(String path) {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(path);
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath);
        return project.currentPackage();
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private void assertTrue(DiagnosticResult diagnosticResult, int index, String message, String code) {
        Diagnostic diagnostic = (Diagnostic) diagnosticResult.diagnostics().toArray()[index];
        Assertions.assertTrue(diagnostic.diagnosticInfo().messageFormat().contains(message));
        Assertions.assertEquals(diagnostic.diagnosticInfo().code(), code);
    }

    @Test
    public void testEmptyQualifierType() {
        Package currentPackage = loadPackage("sample_1_empty_qualifier");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream().filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();

        Assertions.assertEquals(availableErrors, 1);
        diagnosticResult.diagnostics().forEach(result -> {
            if (result.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)) {
                Assertions.assertEquals(result.diagnosticInfo().code(), SFDC_106);
            }
        });
    }

    @Test
    public void testInvalidQualifierType() {
        Package currentPackage = loadPackage("sample_2_invalid_qualifier");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assertions.assertEquals(diagnosticResult.diagnosticCount(), 2);
        assertTrue(diagnosticResult, 0, "", BCE_2);
        assertTrue(diagnosticResult, 1, "", SFDC_107);
    }

    @Test
    public void testInvalidMethodName() {
        Package currentPackage = loadPackage("sample_3_invalid_method_name");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream().filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();

        Assertions.assertEquals(availableErrors, 1);
        diagnosticResult.diagnostics().forEach(result -> {
            if (result.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)) {
                Assertions.assertEquals(result.diagnosticInfo().code(), SFDC_102);
            }
        });
    }

    @Test
    public void testEmptyParameterList() {
        Package currentPackage = loadPackage("sample_4_empty_parameter_list");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream().filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();

        Assertions.assertEquals(availableErrors, 1);
        diagnosticResult.diagnostics().forEach(result -> {
            if (result.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)) {
                Assertions.assertEquals(result.diagnosticInfo().code(), SFDC_103);
            }
        });
    }

    @Test
    public void testMoreThanOneParameterName() {
        Package currentPackage = loadPackage("sample_5_more_than_one_parameter");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream().filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();

        Assertions.assertEquals(availableErrors, 1);
        diagnosticResult.diagnostics().forEach(result -> {
            if (result.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)) {
                Assertions.assertEquals(result.diagnosticInfo().code(), SFDC_104);
            }
        });
    }

    @Test
    public void testInvalidParameterName() {
        Package currentPackage = loadPackage("sample_6_invalid_parameter_type");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream().filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();

        Assertions.assertEquals(availableErrors, 1);
        diagnosticResult.diagnostics().forEach(result -> {
            if (result.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)) {
                Assertions.assertEquals(result.diagnosticInfo().code(), SFDC_105);
            }
        });
    }

    @Test
    public void testEmptyAnnotation() {
        Package currentPackage = loadPackage("sample_7_empty_annotation");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        long availableErrors = diagnosticResult.diagnostics().stream().filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).count();

        Assertions.assertEquals(availableErrors, 1);
        diagnosticResult.diagnostics().forEach(result -> {
            if (result.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)) {
                Assertions.assertEquals(result.diagnosticInfo().code(), SFDC_101);
            }
        });
    }

    @Test
    public void testInvalidAnnotation() {
        Package currentPackage = loadPackage("sample_8_invalid_annotation");
        PackageCompilation compilation = currentPackage.getCompilation();
        DiagnosticResult diagnosticResult = compilation.diagnosticResult();
        Assertions.assertEquals(diagnosticResult.diagnosticCount(), 2);
        assertTrue(diagnosticResult, 0, "", BCE_1);
        assertTrue(diagnosticResult, 1, "", SFDC_101);
    }
}

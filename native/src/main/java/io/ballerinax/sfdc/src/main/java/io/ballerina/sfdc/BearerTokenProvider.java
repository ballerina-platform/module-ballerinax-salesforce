/*
 * Copyright (c) 2016, salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.TXT file in the repo root  or https://opensource.org/licenses/BSD-3-Clause
 */

package io.ballerina.sfdc;

import java.util.function.Function;
import java.util.function.Supplier;

/**
 * Container for io.ballerina.sfdc.BayeuxParameters and the bearerToken.
 * Calls io.ballerina.sfdc.BayeuxParameters supplier in re-authentication scenarios.
 *
 * @author pbn-sfdc
 */
public class BearerTokenProvider implements Function<Boolean, String> {

    private Supplier<BayeuxParameters> sessionSupplier;
    private String bearerToken;

    public BearerTokenProvider(Supplier<BayeuxParameters> sessionSupplier) {
        this.sessionSupplier = sessionSupplier;
    }

    public BayeuxParameters login() throws Exception {
        BayeuxParameters parameters = sessionSupplier.get();
        bearerToken = parameters.bearerToken();
        return parameters;
    }

    @Override
    public String apply(Boolean reAuth) {
        if (reAuth) {
            try {
                bearerToken = sessionSupplier.get().bearerToken();
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }
        return bearerToken;
    }
}

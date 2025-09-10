package com.test_integration.test_integration_app

import androidx.test.ext.junit.rules.ActivityScenarioRule
import dev.flutter.plugins.integration_test.FlutterTestRunner
import org.junit.Rule
import org.junit.runner.RunWith

@RunWith(FlutterTestRunner::class)
class MainActivityTest {
    @Rule
    @JvmField
    val rule = ActivityScenarioRule(MainActivity::class.java)
}


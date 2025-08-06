package com.example.mana_reader

import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import androidx.test.espresso.matcher.ViewMatchers.withId
import org.junit.Assert.assertNotNull
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MainActivityTest {

    @get:Rule
    val activityRule = ActivityScenarioRule(MainActivity::class.java)

    @Test
    fun mainActivityLaunchesAndShowsSplash() {
        activityRule.scenario.onActivity { activity ->
            assertNotNull(activity)
            // Splash screen background should be present when activity starts
            assertNotNull(activity.window.decorView.background)
        }
        onView(withId(android.R.id.content)).check(matches(isDisplayed()))
    }

    @Test
    fun mainActivityHandlesLifecycle() {
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.moveToState(Lifecycle.State.RESUMED)
            scenario.recreate()
            scenario.moveToState(Lifecycle.State.DESTROYED)
        }
    }
}

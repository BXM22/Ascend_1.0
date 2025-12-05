# Project Title

**Ascend - iOS Workout Tracker**

## Authors

<Developer 1 name> (<developer1@csu.fullerton.edu>)

<Developer 2 name> (<developer2@csu.fullerton.edu>)

<Developer 3 name> (<developer3@csu.fullerton.edu>)

<Developer 4 name> (<developer4@csu.fullerton.edu>)

## Background and motivation

Fitness tracking applications often lack intuitive interfaces, comprehensive progress visualization, and structured workout guidance. Many existing solutions are either too complex for casual users or too simplistic for serious fitness enthusiasts. Additionally, most apps don't provide adequate support for different exercise types (weight training, calisthenics, hold exercises) or structured progression systems.

Ascend addresses these gaps by providing a modern, user-friendly iOS application built with SwiftUI that combines real-time workout tracking, automatic progress monitoring, and structured training programs. The app focuses on making fitness tracking seamless and motivating through features like automatic PR detection, visual progress charts, and customizable workout templates. By supporting multiple exercise types including weight/reps exercises and time-based hold exercises, Ascend caters to a broader range of fitness activities from traditional weightlifting to calisthenics skill training.

## Summary

Ascend is an iOS workout tracking application built with SwiftUI that enables users to track exercises, monitor progress through automatic PR detection and visual statistics, and follow structured workout programs and templates. The app features real-time workout tracking with customizable rest timers, support for multiple exercise types (weight/reps and hold exercises), and a modern interface with theme customization.

## Features

**Dashboard & Overview (Developer Name)** - The Dashboard serves as the home screen, displaying key statistics including workout streak, total volume, completed workouts, and training time in a card-based layout with gradient accents. The screen features a workout streak card showing current and longest streaks, a "Recent PRs" section with the three most recent personal records, a "Top Exercises" ranking by PR count, and a weekly summary card, all designed to help users quickly assess progress and stay motivated.

**Workout Tracking & Exercise Management (Developer Name)** - The core workout tracking feature allows users to start, pause, and complete workouts with real-time exercise tracking, supporting both weight/reps exercises (e.g., Bench Press, Squat) and hold exercises (e.g., Plank, Wall Sit) that track duration in seconds. The workout view displays a live timer, exercise navigation tabs for multi-exercise workouts, a prominent exercise card showing current set progress, and automatically triggers a rest timer after completing sets while displaying previous sets for reference, with additional features like alternative exercise suggestions and video tutorial links.

**Rest Timer & Settings (Developer Name)** - The rest timer feature provides a circular progress indicator that automatically starts after completing a set, displaying remaining time with visual progress and allowing users to skip or manually complete the rest period early. The default rest duration is configurable through a settings screen where users can choose from quick options (30s, 45s, 60s, 90s, 2m, 3m, 4m, 5m) or set a custom duration using a slider (30 seconds to 10 minutes), with all preferences persisted using UserDefaults.

**PR Detection & Celebration (Developer Name)** - The app automatically detects personal records (PRs) by comparing the current set's weight and reps against all previous sets for the same exercise at the same weight, and when a user achieves more reps at a given weight than ever before, a prominent PR badge appears with a celebration message (e.g., "PR! +2 reps at 185 lbs"). The badge features a trophy emoji, gradient background, auto-dismisses after 3 seconds with smooth animation, and all PRs are tracked and displayed throughout the app in the dashboard's recent PRs section and the detailed PR tracker, providing immediate positive feedback and motivation during workouts.

**Progress Tracking & Visualization (Developer Name)** - The Progress view features a workout streak card displaying both current and longest streaks with large gradient numbers, and an Exercise PR Tracker that allows users to select any exercise from a dropdown menu to view their current PR (weight × reps) prominently displayed with the achievement date. Below the current PR, a history section shows all previous PRs for that exercise in chronological order with improvement indicators (e.g., "+5 lbs" or "+2 reps"), using gradient cards, borders, and shadows to create visual hierarchy and make progress data easily digestible.

**Workout Templates & Custom Templates (Developer Name)** - The Templates view allows users to create, edit, and start workouts from pre-defined or custom templates, displaying three main sections: Workout Programs (multi-day structured programs), Calisthenics Skills (skill progression programs), and regular Workout Templates. Users can create new templates by entering a template name, adding exercises by name, and setting an estimated duration, and when starting a template, the app automatically creates a new workout with all exercises pre-loaded, streamlining workout creation and ensuring consistency in training routines.


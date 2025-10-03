# Ruby Code Refactoring Prompt

## Overview

I need help refactoring my Ruby code to follow best practices, principles, and appropriate design patterns including:

- Clean Code
- Single Responsibility Principle (SRP)
- Don't Repeat Yourself (DRY)
- Keep It Simple, Stupid (KISS)
- Sandi Metz's Rules
- You Aren't Gonna Need It (YAGNI)
- Design Patterns (GoF patterns and Ruby-specific patterns)
- Other Ruby community standards

## Instructions

1. Please review the code below and identify refactoring opportunities.
2. Provide specific recommendations with before/after examples.
3. Explain the reasoning behind each change.

```ruby
# [PASTE YOUR CODE HERE]
```

## Specific Areas to Address

- **Method Length**: Methods should be under 10 lines (Sandi Metz rule)
- **Class Size**: Classes should be under 100 lines (Sandi Metz rule)
- **Parameter Lists**: No more than 4 parameters per method (Sandi Metz rule)
- **Dependencies**: Limit the number of instance variables used in a method
- **Naming**: Clear, intention-revealing names for variables, methods, and classes
- **Code Organization**: Proper use of modules, classes, and methods
- **Comments**: Reduce the need for comments through clear code
- **Test Coverage**: Ensure refactored code maintains test coverage
- **Performance Considerations**: Note any performance implications of changes

## Design Patterns to Consider

- **Creational Patterns**: Factory Method, Builder, Singleton (use sparingly)
- **Structural Patterns**: Adapter, Decorator, Facade, Composite
- **Behavioral Patterns**: Observer, Strategy, Command, Template Method
- **Ruby-Specific Patterns**: 
  - Service Objects
  - Form Objects
  - Query Objects
  - Presenters/View Models
  - Value Objects
  - Policy Objects
  - Interactors/Use Cases

## Specific Ruby Best Practices

- Proper use of Ruby idioms (e.g., blocks, enumerable methods)
- Effective use of Ruby's standard library
- Following Ruby style conventions (2 space indentation, etc.)
- Appropriate error handling
- Avoiding global state and side effects
- Leveraging Ruby's dynamic features appropriately
- Composition over inheritance
- Duck typing and interface consistency

## Output Format

For each refactoring suggestion:

1. **Issue**: Describe what needs improvement
2. **Before**: Show the problematic code
3. **After**: Show the refactored code
4. **Explanation**: Why this change improves the code
5. **Principles Applied**: Which principles/rules/patterns this change satisfies
# Coding Principles

## 1. KISS (Keep It Simple, Stupid)
Prefer the simplest solution that works. Favor clarity and readability over cleverness. Do not over-engineer.

## 2. Avoid unnecessary design patterns
Only introduce a design pattern when it solves a concrete, obvious problem. Do not force patterns "because it's best practice." A plain function, a switch, or a simple module is often better than a Strategy/Factory/Observer etc.

## 3. Prefer switch over if...else chains
When branching on a single value, use `switch` (or `match`) instead of long `if...else if...else` chains. It's more readable, explicit, and easier to extend.

# Contributing to Ubuntu Server Security Setup

Thank you for your interest in contributing! This project aims to provide a comprehensive, secure, and easy-to-use Ansible automation for Ubuntu server setup.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your environment (OS, Ansible version, etc.)
- Relevant logs or error messages

### Suggesting Enhancements

We welcome feature requests! Please create an issue with:
- Clear description of the enhancement
- Use case and benefits
- Any implementation ideas

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow existing code style
   - Test your changes thoroughly
   - Update documentation if needed

4. **Test your changes**
   ```bash
   # Syntax check
   ansible-playbook playbook.yml --syntax-check
   
   # Dry run
   ansible-playbook playbook.yml --check
   ```

5. **Commit your changes**
   ```bash
   git commit -m "Add: description of your changes"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**

## Coding Guidelines

### Ansible Best Practices

- Use meaningful variable names
- Add comments for complex tasks
- Keep roles modular and focused
- Use handlers for service restarts
- Include check mode support (`--check`)
- Ensure idempotency

### YAML Style

```yaml
---
# Use 2 spaces for indentation
- name: Task description starts with capital letter
  module_name:
    parameter: value
    another_parameter: value
  when: condition
  tags: [tag1, tag2]
```

### Documentation

- Update README.md for user-facing changes
- Update DEPLOYMENT_GUIDE.md for process changes
- Add inline comments for complex logic
- Include examples in documentation

### Security

- Never commit sensitive data
- Use variables for configurable items
- Follow security best practices
- Test security features thoroughly

## Testing

Before submitting:

1. **Syntax Check**
   ```bash
   ansible-playbook playbook.yml --syntax-check
   ```

2. **Dry Run**
   ```bash
   ansible-playbook playbook.yml --check
   ```

3. **Test on Clean System**
   - Use a fresh Ubuntu VM
   - Test all playbooks
   - Verify all features work

4. **Documentation**
   - Ensure examples work
   - Check for typos
   - Verify links

## Areas for Contribution

We especially welcome contributions in:

- **Additional Roles**: New security tools, monitoring solutions
- **Platform Support**: Support for other OS versions
- **Testing**: Automated testing with Molecule
- **Documentation**: Tutorials, examples, translations
- **Bug Fixes**: Improvements to existing code
- **Performance**: Optimization of playbooks

## Code Review Process

1. All PRs require review
2. Automated checks must pass
3. Documentation must be updated
4. Changes must be tested
5. Security implications reviewed

## Community

- Be respectful and constructive
- Help others in issues and discussions
- Share your use cases and feedback
- Improve documentation

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion
- Reach out to maintainers

Thank you for contributing! 🎉

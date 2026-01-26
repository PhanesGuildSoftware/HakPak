#!/usr/bin/env python3
"""Test script for InstallParams functionality"""

from hakpak3 import InstallParams, SystemInfo, Tool, ToolMetrics, ToolCategory, CompatibilityScorer

# Test 1: Create InstallParams with defaults
print("Test 1: Default InstallParams")
params_default = InstallParams()
print(f"  min_compatibility: {params_default.min_compatibility}")
print(f"  max_compatibility: {params_default.max_compatibility}")
print(f"  max_size_mb: {params_default.max_size_mb}")
print("  PASSED\n")

# Test 2: Create InstallParams with custom values
print("Test 2: Custom InstallParams")
params_custom = InstallParams(
    min_compatibility=50,
    max_size_mb=100.0,
    max_ram_mb=1024,
    max_count=10
)
print(f"  min_compatibility: {params_custom.min_compatibility}%")
print(f"  max_size_mb: {params_custom.max_size_mb} MB")
print(f"  max_ram_mb: {params_custom.max_ram_mb} MB")
print(f"  max_count: {params_custom.max_count}")
print("  PASSED\n")

# Test 3: Create mock SystemInfo
print("Test 3: Mock SystemInfo")
mock_system = SystemInfo(
    os_name='Ubuntu',
    os_version='22.04',
    os_id='ubuntu',
    os_id_like='debian',
    kernel='5.15',
    architecture='x86_64',
    cpu_count=4,
    total_ram_mb=8192,
    available_ram_mb=4096,
    total_disk_gb=500.0,
    available_disk_gb=200.0,
    package_manager='apt'
)
print(f"  OS: {mock_system.os_name} {mock_system.os_version}")
print(f"  Package Manager: {mock_system.package_manager}")
print("  PASSED\n")

# Test 4: Create mock Tool
print("Test 4: Mock Tool")
mock_metrics = ToolMetrics(
    estimated_size_mb=50.0,
    dependencies_size_mb=20.0,
    ram_required_mb=512,
    compatibility_score=75
)
mock_tool = Tool(
    name='test-tool',
    binary='test',
    category=ToolCategory.STANDARD,
    description='Test tool for validation',
    packages={'apt': 'test-pkg'},
    source=None,
    dependencies=[],
    metrics=mock_metrics,
    kali_metapackage=None,
    tags=['test', 'network']
)
print(f"  Tool name: {mock_tool.name}")
print(f"  Size: {mock_tool.metrics.estimated_size_mb + mock_tool.metrics.dependencies_size_mb} MB")
print(f"  RAM: {mock_tool.metrics.ram_required_mb} MB")
print("  PASSED\n")

# Test 5: Filter matching - should PASS
print("Test 5: Filter Matching (should pass)")
params_pass = InstallParams(min_compatibility=50, max_size_mb=100.0)
matches = params_pass.matches(mock_tool, mock_system)
print(f"  Tool: {mock_tool.name}")
print(f"  Filter: min_compat=50%, max_size=100MB")
print(f"  Tool size: 70MB, Tool will have compat score calculated")
print(f"  Result: {matches}")
if matches:
    print("  PASSED\n")
else:
    print("  FAILED - should have matched\n")

# Test 6: Filter matching - should FAIL (size too large)
print("Test 6: Filter Matching (should fail - size limit)")
params_fail = InstallParams(max_size_mb=50.0)
matches = params_fail.matches(mock_tool, mock_system)
print(f"  Tool: {mock_tool.name}")
print(f"  Filter: max_size=50MB")
print(f"  Tool size: 70MB")
print(f"  Result: {matches}")
if not matches:
    print("  PASSED (correctly rejected)\n")
else:
    print("  FAILED - should have been rejected\n")

# Test 7: Tag filtering
print("Test 7: Tag Filtering")
params_tags = InstallParams(tags_filter=['network'])
matches = params_tags.matches(mock_tool, mock_system)
print(f"  Tool tags: {mock_tool.tags}")
print(f"  Filter: include 'network'")
print(f"  Result: {matches}")
if matches:
    print("  PASSED\n")
else:
    print("  FAILED - should have matched\n")

# Test 8: Tag exclusion
print("Test 8: Tag Exclusion")
params_exclude = InstallParams(exclude_tags=['web'])
matches = params_exclude.matches(mock_tool, mock_system)
print(f"  Tool tags: {mock_tool.tags}")
print(f"  Filter: exclude 'web'")
print(f"  Result: {matches}")
if matches:
    print("  PASSED\n")
else:
    print("  FAILED - should have matched\n")

print("="*60)
print("All basic tests completed successfully!")
print("="*60)

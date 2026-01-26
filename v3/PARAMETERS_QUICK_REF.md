# Quick Reference: Installation Parameters

## Quick Command Examples

### Filter by Compatibility
```
Install Tools with Filters → 
  Minimum compatibility %: 50
  → Shows only tools with ≥50% compatibility
```

### Filter by Size
```
Install Tools with Filters →
  Maximum size in MB: 200
  → Shows only tools ≤200MB total size
```

### Filter by RAM
```
Install Tools with Filters →
  Maximum RAM in MB: 1024
  → Shows only tools requiring ≤1GB RAM
```

### Filter by Tags (Include)
```
Install Tools with Filters →
  Include tags: web,network
  → Shows only web or network tools
```

### Filter by Tags (Exclude)
```
Install Tools with Filters →
  Exclude tags: wireless,forensics
  → Hides wireless and forensics tools
```

### Limit Number of Tools
```
Install Tools with Filters →
  Maximum tools: 10
  → Shows only top 10 best matches
```

## Common Combinations

### "Show me reliable tools only"
- Minimum compatibility: `70`

### "Small, reliable tools"
- Minimum compatibility: `60`
- Maximum size: `100`

### "Top 5 web tools"
- Include tags: `web,http`
- Minimum compatibility: `50`
- Maximum tools: `5`

### "Network tools for low-spec system"
- Include tags: `network,scanning`
- Maximum size: `150`
- Maximum RAM: `512`
- Minimum compatibility: `50`

### "Install everything compatible"
- Minimum compatibility: `50`
- Type 'all' when prompted

## Compatibility Score Guide

- **80-100%**: Excellent - Native packages, perfect fit
- **60-79%**: Good - Will work with minor setup
- **40-59%**: Fair - May need source build
- **0-39%**: Poor - Limited support

**Recommended minimum**: `50` for reliable installs

## Parameter Defaults

| Parameter | Default | Meaning |
|-----------|---------|---------|
| min_compatibility | 0 | No minimum |
| max_compatibility | 100 | No maximum |
| max_size_mb | None | No limit |
| max_ram_mb | None | No limit |
| tags_filter | None | All tags |
| exclude_tags | None | No exclusions |
| max_count | None | No limit |

## Pro Tips

1. **Start with compatibility**: Set min to 50-60 first
2. **Combine filters**: Use multiple criteria together
3. **Check results**: Look at "X tools match" message
4. **Adjust if needed**: No matches? Relax filters
5. **Use 'all' wisely**: Review the list before typing 'all'
6. **Iterate**: Run multiple filtered installs with different criteria

## Interactive Flow

```
Menu → 3) Install Tools with Filters
│
├─ Minimum compatibility % [0]: 50
├─ Maximum compatibility % [100]: [Enter]
├─ Maximum size MB [no limit]: 200
├─ Maximum RAM MB [no limit]: [Enter]
├─ Include tags [all]: network
├─ Exclude tags [none]: wireless
├─ Maximum tools [no limit]: 10
│
└─ Shows filtered results →
   │
   ├─ Type 'all' → Install top matches
   ├─ Type tool names → Install specific ones
   ├─ Type 'search' → Search within filtered set
   └─ Type 'filter' → Reconfigure parameters
```

---

**Quick Access**: Main Menu → Option 3  
**Documentation**: See INSTALL_PARAMETERS.md for detailed guide

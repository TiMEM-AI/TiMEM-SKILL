# COS publication

Public origin: `https://careerfun-1257357192.cos.ap-beijing.myqcloud.com`.
The publisher checks the CI bucket/region against this origin before uploading.

CI tests Windows and Bash installers, builds complete release and full Skill ZIPs,
then uploads immutable version objects, compatibility aliases, and finally
`releases/latest.json`. All publishing runs share one concurrency group.
PR runs build and test only.

Installers read `latest.json` once, obtain its versioned release manifest and ZIP,
verify the ZIP size and SHA-256, then extract the package. Failed verification stops
installation. Compatibility latest aliases are individually replaced; consumers
requiring a consistent snapshot must use the manifest's versioned paths.

The source of the full package is `skills/timem-memory-skill/`; the build copies it
recursively to `dist/full/timem-memory-skill/`. Add future files to the source tree,
not only to generated dist output. New nested files are automatically packaged.

Public installer entry points:

- `installers/install-all.ps1` (preserve UTF-8 BOM and `.TrimStart([char]0xFEFF)`)
- `installers/install-all.sh`

Publish and verify these before deploying frontend commands referencing them.
CI runs `scripts/verify_cos_public.py --version VERSION` after uploading; it checks
the versioned ZIPs and both versioned/stable installers using anonymous GETs.

For Windows offline/configuration regression testing, `TIMEM_SKILL_SOURCE_DIR`
can point to an extracted release root containing the required Skill directories.

Rollback: restore installer aliases from a previously verified version, then
restore its saved `latest.json` pointer as the final step. If no pointer was saved,
reconstruct it with that version and its immutable artifact keys using the same
schema as the builder. Never copy a `release-manifest-*.json` directly over
`latest.json`: the two schemas differ. Do not overwrite version objects.
The uploader refuses a conflicting hash at an existing version path.

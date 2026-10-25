const importPattern=/import\s*\{\s*createHash\s*\}\s*from\s*['"]node:crypto['"];?\s*/;
const hashPattern=/createHash\(['"]sha256['"]\)\.update\(JSON\.stringify\(attestation\)\)\.digest\(['"]hex['"]\)/;

export function portableEvidenceBody(source: string): string{
 if(!importPattern.test(source)||!hashPattern.test(source))throw new Error('The evidence engine changed; update platform bundles deliberately.');
 return source
  .replace(importPattern,'')
  .replaceAll('export const ','const ')
  .replaceAll('export function ','function ')
  .replace(hashPattern,'__sha256(JSON.stringify(attestation))')
  .replace(/^\/\/# sourceMappingURL=.*$/m,'');
}

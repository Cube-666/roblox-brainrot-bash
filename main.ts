// Brainrot Bash — the handoff program for the roblox-brainrot-01 entry (Node 22, standard library only).
//
// It hands the built game to the grader: game.rbxl (the Rojo build of the Brainrot Bash place),
// PLAY.json (the published place's ids), src/ (the Luau sources) and screenshots/ (playtest shots,
// first by name is the cover) are copied from beside this file to the output directory, and
// dossier.json — the summary the judge reads — is written there by the vendored make.fun library.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

// The repository root (this file lives in it) and the directory the grader reads.
const repoRoot = fileURLToPath(new URL('.', import.meta.url));
const targetDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** cpSync's filter: skip every file and directory whose name starts with a dot. */
const visible = (path: string): boolean => !basename(path).startsWith('.');

/** The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the rest refuse an entry the scorer would refuse. */
const scorerCaps = {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
};

// Fail early with a readable message when a required input is missing, instead of a raw ENOENT from copyFileSync.
for (const needed of ['game.rbxl', 'PLAY.json']) {
  if (!existsSync(join(repoRoot, needed))) {
    throw new Error(`Brainrot Bash: ${needed} is missing from the repository — build it (rojo build) or fill it in (PLAY.json) before handing the game in.`);
  }
}

copyFileSync(join(repoRoot, 'game.rbxl'), join(targetDir, 'game.rbxl'));
copyFileSync(join(repoRoot, 'PLAY.json'), join(targetDir, 'PLAY.json'));
cpSync(join(repoRoot, 'src'), join(targetDir, 'src'), { recursive: true, filter: visible });
mkdirSync(join(targetDir, 'screenshots'), { recursive: true });
if (existsSync(join(repoRoot, 'screenshots'))) {
  cpSync(join(repoRoot, 'screenshots'), join(targetDir, 'screenshots'), { recursive: true, filter: visible });
}

writeFileSync(join(targetDir, 'dossier.json'), buildDossier(targetDir, scorerCaps));

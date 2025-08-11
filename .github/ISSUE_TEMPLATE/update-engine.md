---
name: "Atualização de Engine"
about: "Template para atualização da engine do projeto (ex.: Godot, Unity, Unreal)"
title: "Atualizar [Nome do Projeto] para [Engine] [Nova Versão]"
labels: ["update", "engine", "maintenance"]
assignees: []
---

# Atualizar {{ nome_do_projeto }} para {{ engine }} {{ nova_versao }}

## Contexto
O projeto atualmente utiliza **{{ engine }} {{ versao_atual }}**.  
Será feita a atualização para **{{ engine }} {{ nova_versao }}** para aproveitar melhorias, correções de bugs e novos recursos.

## Objetivos
- Garantir compatibilidade total com {{ engine }} {{ nova_versao }}.
- Corrigir eventuais erros causados pela atualização.
- Testar funcionalidades críticas.

## Tarefas
- [ ] Abrir o projeto na nova versão e permitir a conversão automática dos arquivos.
- [ ] Atualizar a documentação (`README.md`) informando a nova versão da engine.

## Como executar esta issue

### 1. Criar um novo branch a partir da `master`
```bash
git checkout master
git pull origin master
git checkout -b update/{{ engine | lower }}-{{ nova_versao }}

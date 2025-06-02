#!/bin/bash

# Caminho base do projeto (ajuste conforme necessário)
BASE_DIR="lib"

# Diretórios alvo
mkdir -p $BASE_DIR/views/checkin
mkdir -p $BASE_DIR/views/events
mkdir -p $BASE_DIR/views/dashboard
mkdir -p $BASE_DIR/views/profile
mkdir -p $BASE_DIR/widgets
mkdir -p $BASE_DIR/models
mkdir -p $BASE_DIR/services
mkdir -p $BASE_DIR/controllers

# Arquivos de Views
touch $BASE_DIR/views/checkin/checkpoint_questions_view.dart
touch $BASE_DIR/views/checkin/challenge_view.dart
touch $BASE_DIR/views/checkin/hint_popup.dart
touch $BASE_DIR/views/events/final_activities_view.dart
touch $BASE_DIR/views/dashboard/ranking_detailed_view.dart
touch $BASE_DIR/views/profile/team_customization_view.dart

# Arquivos de Models
touch $BASE_DIR/models/challenge.dart
touch $BASE_DIR/models/hint.dart
touch $BASE_DIR/models/final_activity.dart

# Arquivos de Services
touch $BASE_DIR/services/challenge_service.dart
touch $BASE_DIR/services/hint_service.dart

# Arquivos de Controllers
touch $BASE_DIR/controllers/final_activities_controller.dart

# Widgets compartilhados
touch $BASE_DIR/widgets/question_card.dart
touch $BASE_DIR/widgets/hint_dialog.dart
touch $BASE_DIR/widgets/score_input_card.dart

echo "✅ Arquivos e diretórios criados com sucesso!"


extends Area2D

var activated := false
var player_on_black_hole := false
var size := 1
var victim: Node2D = null
var consuming : bool = false


# -----------------------------------------------------------------------------
# Disparado quando um corpo entra na área do buraco negro.
# Comportamento:
#   - Se for o player (possui método is_player):
#       • Guarda a referência em `victim` e marca presença (`player_on_black_hole`).
#       • Se o buraco já estiver ativado e ainda não estiver consumindo, inicia
#         imediatamente a animação de consumo; senão, arma o ActivateTimer.
#   - Se não for o player:
#       • Remove o corpo da cena e pede para o Level repor um asteroide.
# Parâmetros:
#   body (Node2D) ... Corpo que acabou de entrar na área.
# -----------------------------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("is_player"):
		victim = body
		player_on_black_hole = true
		
		if activated and not consuming:
			_start_consume_now()
		else:
			$ActivateTimer.start()
	else:
		body.queue_free()
		Singleton.level.spawn_asteroid()


# -----------------------------------------------------------------------------
# Atualização por frame (física).
# Comportamento:
#   - Toca a animação do sprite do buraco negro variando entre "default" e
#     "quantum" conforme o estado `Singleton.level.quantum`.
# Parâmetros:
#   _delta (float) ... Tempo do frame (não usado diretamente).
# -----------------------------------------------------------------------------
func _physics_process(_delta: float) -> void:
	$AnimatedSprite2D.play( "default" if not Singleton.level.quantum else "quantum" )


# -----------------------------------------------------------------------------
# Disparado quando um corpo sai da área do buraco negro.
# Comportamento:
#   - Se for o player, desmarca a presença e limpa a referência de `victim`
#     quando ela apontar para o mesmo nó que saiu.
# Parâmetros:
#   body (Node2D) ... Corpo que acabou de sair da área.
# -----------------------------------------------------------------------------
func _on_body_exited(body: Node2D) -> void:
	if body.has_method("is_player"):
		player_on_black_hole = false
		if victim == body:
			victim = null


# -----------------------------------------------------------------------------
# Callback de timer responsável por aumentar gradualmente o tamanho do buraco.
# Comportamento:
#   - Até `size` atingir 20, aplica um scale progressivo (×1.1) e incrementa a
#     contagem.
# -----------------------------------------------------------------------------
func _on_increase_size_timeout() -> void:
	if size < 20:
		scale *= 1.1
	size += 1


# -----------------------------------------------------------------------------
# Callback do timer de ativação do buraco negro.
# Comportamento:
#   - Marca o buraco como ativado.
#   - Se o player ainda estiver dentro, `victim` for válida e ainda não houver
#     consumo em andamento, inicia a animação de consumo agora.
# -----------------------------------------------------------------------------
func _on_activate_timer_timeout() -> void:
	activated = true
	if player_on_black_hole and not consuming and is_instance_valid(victim):
		_start_consume_now()


# -----------------------------------------------------------------------------
# Inicia o processo de “consumo” do player pelo buraco negro.
# Comportamento:
#   - Evita reentrância com a flag `consuming`.
#   - Se existir um player válido com o método `start_black_hole_death`, chama-o
#     passando o centro do buraco negro.
#   - Caso contrário, aciona imediatamente o Game Over como fallback.
# -----------------------------------------------------------------------------
func _start_consume_now() -> void:
	consuming = true
	if is_instance_valid(victim) and victim.has_method("start_black_hole_death"):
		victim.start_black_hole_death(global_position)
	else:
		# fallback, se por algum motivo não houver player/método
		Singleton.game_over()

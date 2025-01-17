# frozen_string_literal: true

class AgentMailer < ApplicationMailer

  default from: "equipe@dossiersco.fr",
          reply_to: "equipe@dossiersco.fr"

  def succes_import(email, statistiques)
    @statistiques = statistiques
    mail(subject: "Import de votre base élève dans DossierSCO", to: email, &:text)
  end

  def succes_import_nomenclature(email)
    mail(subject: "Import de votre nomenclature dans DossierSCO", to: email, &:text)
  end

  def succes_import_responsables(email)
    mail(subject: "Import des responsables dans DossierSCO", to: email, &:text)
  end

  def succes_import_eleves(email)
    mail(subject: "Import des élèves dans DossierSCO", to: email, &:text)
  end

  def erreur_import(email)
    mail(subject: "L'import de votre base élève a échoué", to: email, &:text)
  end

  def invite_premier_agent(agent)
    @agent = agent
    mail(subject: "Activez votre compte DossierSCO", to: @agent.email) do |format|
      format.html
      format.text
    end
  end

  def invite_agent(agent_invite, admin)
    @agent_invite = agent_invite
    @admin = admin
    mail(subject: "Activez votre compte agent sur DossierSCO", to: @agent_invite.email) do |format|
      format.html
      format.text
    end
  end

  def convocation(agent, fichier)
    @agent = agent
    @fichier = fichier

    mail(subject: "Convocations pour l'inscription sur DossierSCO", to: @agent.email) do |format|
      format.html
      format.text
    end
  end

  def change_mot_de_passe_agent(agent)
    @agent = agent
    mail(subject: "changer votre mot de passe sur DossierSCO", to: @agent.email) do |format|
      format.html
      format.text
    end
  end

end

/* QBCore */
ALTER TABLE player_vehicles
    ADD  rentfinish DATE NOT NULL DEFAULT '2999-06-01';

/* ESX */

ALTER TABLE owned_vehicles
    ADD  rentfinish DATE NOT NULL DEFAULT '2999-06-01';

/*  vRP */

ALTER TABLE vrp_user_vehicles
    ADD  rentfinish DATE NOT NULL DEFAULT '2999-06-01';
